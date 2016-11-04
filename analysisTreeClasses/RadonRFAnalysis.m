classdef RadonRFAnalysis < AnalysisTree
    properties
        StartTime = 0
        EndTime = 0;
        respType = 'Charge';
        RF_microns = 500;
    end
    
    methods
        function obj = RadonRFAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
                        
            nameStr = [cellData.savedFileName ': ' dataSetName ': RadonRFAnalysis'];
            obj = obj.setName(nameStr);
            obj = obj.copyAnalysisParams(params);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY', 'Nangles', 'Npositions', 'barSeparation', 'barWidth'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'barAngle', 'barStep'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            %percolateUp to angle level
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'barPositions');
        
            %baseline subtraction and normalization (factor out in the
            %future?
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                for i=1:L %for each leaf node
                    curNode = obj.get(leafIDs(i));
                    %baseline subtraction
                    grandBaselineMean = outputStruct.baselineRate.mean_c;
                    tempStruct.ONSETrespRate_grandBaselineSubtracted = curNode.ONSETrespRate;
                    tempStruct.ONSETrespRate_grandBaselineSubtracted.value = curNode.ONSETrespRate.value - grandBaselineMean;
                    tempStruct.OFFSETrespRate_grandBaselineSubtracted = curNode.OFFSETrespRate;
                    tempStruct.OFFSETrespRate_grandBaselineSubtracted.value = curNode.OFFSETrespRate.value - grandBaselineMean;
                    tempStruct.ONSETspikes_grandBaselineSubtracted = curNode.ONSETspikes;
                    tempStruct.ONSETspikes_grandBaselineSubtracted.value = curNode.ONSETspikes.value - grandBaselineMean.*curNode.ONSETrespDuration.value; %fix nan and INF here
                    tempStruct.OFFSETspikes_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*curNode.OFFSETrespDuration.value;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted = curNode.spikeCount_ONSET_400ms;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted.value = curNode.spikeCount_ONSET_400ms.value - grandBaselineMean.*0.4; %fix nan and INF here
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*0.4;
                    tempStruct = getEpochResponseStats(tempStruct);
                    
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                radonFields = {'ONSETspikes', 'OFFSETspikes'};
            else
                radonFields = {'ONSET_avgTracePeak', 'OFFSET_avgTracePeak', 'ONSET_chargeT25', 'OFFSET_chargeT25'};
            end
            
            for f=1:length(radonFields)
                fname = radonFields{f};
                radonMat = zeros(rootData.Nangles, rootData.Npositions);
                chInd = obj.getchildren(1); %angle nodes
                angles = zeros(1, rootData.Nangles);
                for i=1:length(chInd)
                    curData = obj.get(chInd(i));
                    angles(i) = curData.splitValue;
                    radonMat(i,:) = getRespVectors(curData, {radonFields{f}});
                end
                
                blankRF = zeros(obj.RF_microns, obj.RF_microns);
                radonMat = flipud(radonMat');
                radonSize = 2*ceil(norm(size(blankRF)-floor((size(blankRF)-1)/2)-1))+3; %from radon.m documentation
                radonMat_resized = zeros(radonSize, rootData.Nangles);
                
                scaleFactor = radonSize/size(blankRF,1);
                
                for i=1:rootData.Nangles
                    radonMat_resized(:,i) = interp1(curData.barPositions * scaleFactor + floor(radonSize/2),  radonMat(:,i), 1:radonSize, ...
                        'linear', 0);
                end
                
                rootData.(['radonMat_' fname]) = radonMat_resized;
                rootData.(['RF_' fname]) = iradon(radonMat_resized, angles, 'v5cubic', 'Hamming', .1, obj.RF_microns);
%                 [~, maxloc] = max(rootData.RF(:));
%                 [y, x] = ind2sub(size(rootData.RF), maxloc);
%                 rootData.Xoffset = floor(obj.RF_microns/2) + x;
%                 rootData.Yoffset = floor(obj.RF_microns/2) + y;
            end
            obj = obj.set(1, rootData);                
        end        
    end
    
    methods(Static)       
        function plotRF_ONSETspikes(node, cellData)
            rootData = node.get(1);
            imagesc(flipud(rootData.RF_ONSETspikes));
        end
        
        function plotRF_OFFSETspikes(node, cellData)
            rootData = node.get(1);
            imagesc(flipud(rootData.RF_OFFSETspikes));
        end
        
        function plotRF_ONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            imagesc(flipud(rootData.RF_ONSET_avgTracePeak));
        end
        
        function plotRF_OFFSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            imagesc(flipud(rootData.RF_OFFSET_avgTracePeak));
        end
        
    end
    
end
