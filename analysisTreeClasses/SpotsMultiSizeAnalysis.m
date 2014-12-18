classdef SpotsMultiSizeAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 1000;
        respType = 'Charge';
    end
    
    methods
        function obj = SpotsMultiSizeAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.rawfilename ': ' dataSetName ': SpotsMultiSizeAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);    
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'curSpotSize'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                else
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                end
                N = length(resp);
                curNode.resp = resp;
                curNode.respMean = mean(resp);
                curNode.respSEM = std(resp)./sqrt(N);
                curNode.N = N;
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'N', 'N', ...
                'splitValue', 'spotSize');
            
            rootData = obj.get(1);
            rootData.respSEM_norm = rootData.respSEM ./ max(rootData.respMean);
            rootData.respMean_norm = rootData.respMean ./ max(rootData.respMean);
            obj = obj.set(1, rootData);
        end
        
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            rootData = node.get(1);
            errorbar(rootData.spotSize, rootData.respMean, rootData.respSEM);
            xlabel('Spot size (microns)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Spike count (norm)');
            else
                ylabel('Charge (pC)');
            end
        end
        
    end
    
end