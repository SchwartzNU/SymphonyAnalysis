classdef AutoCenterAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = AutoCenterAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
                params.holdSignalParam = 'ampHoldSignal';
            else
                params.ampModeParam = 'amp2Mode';
                params.holdSignalParam = 'amp2HoldSignal';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': AutoCenterAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {params.ampModeParam, params.holdSignalParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'sessionId','presentationId'});
        end
        
        function obj = doAnalysis(obj, cellData)
            leafIDs = obj.getchildren(1);
            L = length(leafIDs);
            for leaf_index = 1:L
                curNode = obj.get(leafIDs(leaf_index));

                outputStruct = getAutoCenterRF(cellData, curNode.epochID);
                curNode = mergeIntoNode(curNode, outputStruct);
                
                obj = obj.set(leafIDs(leaf_index), curNode);
                
                [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
                obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
                obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
                obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            end
        end
    end
    
    methods(Static)
        
        function plotSpatial(node, ~)
            
            nodeData = node.get(1);

            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(11);
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'spatial');

                    end
                end
            end
        end
        
        function plotSubunit(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(12);
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'subunit');
                    end
                end
            end
        end        
    end
end

