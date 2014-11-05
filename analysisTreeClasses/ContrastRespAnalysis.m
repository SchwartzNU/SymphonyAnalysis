classdef ContrastRespAnalysis < AnalysisTree
    properties
        respType = 'Charge';
    end
    
    methods
        function obj = ContrastRespAnalysis(cellData, dataSetName, params)
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
            allBaselineSpikes = []; 
            for i=1:L 
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [baselineSpikes, respUnits, baselineLen] = getEpochResponses(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName);
                    [spikes, respUnits, intervalLen] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName);
                    N = length(spikes); 
                    %'EndTime', 250);
                else
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName);
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
            
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'N', 'N', ...
                'splitValue', 'contrast');
        end
    end
    
    methods(Static)
        
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