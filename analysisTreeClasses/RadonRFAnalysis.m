classdef RadonRFAnalysis < AnalysisTree
    properties
        StartTime = 0
        EndTime = 0;
        respType = 'Charge';
        RF_microns = 800;
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
            allBaselineSpikes = []; 
            for i=1:L
                curNode = obj.get(leafIDs(i));                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [baselineSpikes, respUnits, baselineLen] = getEpochResponses(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    [spikes, respUnits, intervalLen] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(spikes);
                else
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(resp);
                end
                
                curNode.N = N;
                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    allBaselineSpikes = [allBaselineSpikes, baselineSpikes];
                    curNode.spikes = spikes;
                else
                    curNode.resp = resp;
                    curNode.respMean = mean(resp);
                    curNode.respSEM = std(resp)./sqrt(N);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            %subtract baseline
            baselineMean = mean(allBaselineSpikes);
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                for i=1:L
                    curNode = obj.get(leafIDs(i));
                    curNode.resp = curNode.spikes - (baselineMean * intervalLen/baselineLen);
                    curNode.respMean = mean(curNode.resp);
                    curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            %percolateUp to angle level
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'respVar', 'respVar', ...
                'N', 'N', ...
                'splitValue', 'barPositions');
        
            radonMat = zeros(rootData.Nangles, rootData.Npositions);            
            chInd = obj.getchildren(1); %angle nodes
            angles = zeros(1, rootData.Nangles);
            for i=1:length(chInd);                
                curData = obj.get(chInd(i)); 
                angles(i) = curData.splitValue;
                radonMat(i,:) = curData.respMean;
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
                        
            rootData.radonMat = radonMat_resized;
            rootData.RF = iradon(rootData.radonMat, angles, 'v5cubic', 'Hamming', .1, obj.RF_microns);
            [~, maxloc] = max(rootData.RF(:));
            [y, x] = ind2sub(size(rootData.RF), maxloc);
            rootData.Xoffset = floor(obj.RF_microns/2) + x;
            rootData.Yoffset = floor(obj.RF_microns/2) + y;
            obj = obj.set(1, rootData);                
        end        
    end
    
    methods(Static)       
        function plotData(node, cellData)
            rootData = node.get(1);
            imagesc(flipud(rootData.RF));
        end
        
    end
    
end
