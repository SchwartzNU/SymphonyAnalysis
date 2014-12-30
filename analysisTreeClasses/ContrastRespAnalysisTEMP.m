classdef ContrastRespAnalysisTEMP < AnalysisTree
    properties
        respType = 'Charge';
    end
    
    methods
        function obj = ContrastRespAnalysisTEMP(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': ContrastRespAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam, 'spotSize', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'contrast'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponsesTEMP(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    disp('Whole-cell not yet implemented');
                    return
                    %                     [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName, ...
                    %                         'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    %                     N = length(resp);
                    %                     curNode.resp = resp;
                    %                     curNode.respMean = mean(resp);
                    %                     curNode.respSEM = std(resp)./sqrt(N);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'contrast');
            
            %baseline subtraction and normalization (factor out in the
            %future?
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
                tempStruct = getEpochResponseStats(tempStruct);         
    
                curNode = mergeIntoNode(curNode, tempStruct);
                obj = obj.set(leafIDs(i), curNode);         
            end
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            
            %normalization
            curNode = addNormalizedFields(curNode, ...
                {...
                'ONSETrespRate_grandBaselineSubtracted', 'OFFSETrespRate_grandBaselineSubtracted', ...
                'ONSETspikes_grandBaselineSubtracted', 'OFFSETspikes_grandBaselineSubtracted', ...
                'ONSETrespRate', 'OFFSETrespRate', ...
                'ONSETspikes', 'OFFSETspikes', ...
                'ONSET_FRmax', 'OFFSET_FRmax', ...
                'ONSETpeakInstantaneousFR', 'OFFSETpeakInstantaneousFR', ...
                });
            
%             [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
%             obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
%             obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
%             obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);            
            
            obj = obj.set(leafIDs(i), curNode);            
             
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'contrast'};
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
        
        function plot_contrastVsspikeCount_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField(1).units, 's')
                for i=1:length(yField)
                    yvals(i) = yField(i).median_c;
                    errs(i) = yField(i).SEM;
                end
            else
                for i=1:length(yField)
                    yvals(i) = yField(i).mean_c;
                    errs(i) = yField(i).SEM;
                end
            end
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval (' yField(1).units ')']);
        end
        
        function plot_contrastVsspikeCount_stimInterval_baselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval_baselineSubtracted;
            if strcmp(yField(1).units, 's')
                for i=1:length(yField)
                    yvals(i) = yField(i).median_c;
                    errs(i) = yField(i).SEM;
                end
            else
                for i=1:length(yField)
                    yvals(i) = yField(i).mean_c;
                    errs(i) = yField(i).SEM;
                end
            end
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField(1).units ')']);
        end
        
        function plotData(node, cellData)
            rootData = node.get(1);
            errorbar(rootData.contrast, rootData.respMean, rootData.respSEM);
            xlabel('Contrast');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Spike count (norm)');
            else
                ylabel('Charge (pC)');
            end
        end
        
    end
    
end