classdef RF1DAnalysis < AnalysisTree
    properties
        
    end
    
    methods
        function obj = RF1DAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': RF1DAnalysis'];
            obj = obj.setName(nameStr);
            obj = obj.copyAnalysisParams(params);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam});
            obj = obj.buildCellTree(1, cellData, dataSet, {'probeAxis', @(epoch)barPosition(epoch)});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, 'Peak firing rate', 'DeviceName', rootData.deviceName);
                else
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, 'CycleAvgF1', 'DeviceName', rootData.deviceName);
                end
                N = length(resp);
                curNode.resp = resp;
                curNode.respUnits = respUnits;
                curNode.respMean = mean(resp);
                curNode.respSEM = std(resp)./sqrt(N);
                curNode.N = N;
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'N', 'N', ...
                'splitValue', 'position');
        end
        
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            %plots for one probeAxis, on that level of the tree
            rootData = node.get(1);
            if ~isfield(rootData, 'splitParam') || ~strcmp(rootData.splitParam, 'probeAxis') %wrong tree level
                cla;
                return
            end
            errorbar(rootData.position, rootData.respMean, rootData.respSEM);
            title(rootData.splitValue);
            xlabel('position (um)');
            chInd = node.getchildren(1);
            ylabel(node.get(chInd(1)).respUnits);
        end
        
    end
    
end

