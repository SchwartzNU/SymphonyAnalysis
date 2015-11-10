classdef SplitFieldAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = SplitFieldAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': SplitFieldAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'barAngle', @(epoch)barPosition2D(epoch)});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);

            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'position');
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            %fnames = fnames{1};
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
         
            %add lists to angleNodes
            angleNodes = getTreeLevel(obj,'barAngle');
            for i=1:length(angleNodes)
                curData = obj.get(angleNodes(i));
                curData.byEpochParamList = byEpochParamList;
                curData.singleValParamList = singleValParamList;
                curData.collectedParamList = collectedParamList;
                curData.stimParameterList = {'position'};
                obj = obj.set(angleNodes(i), curData);
            end
            
%             %to add more here
%             rootData = obj.get(1);
%             rootData.byEpochParamList = byEpochParamList;
%             rootData.singleValParamList = singleValParamList;
%             rootData.collectedParamList = collectedParamList;
%             rootData.stimParameterList = {'position'};
%             obj = obj.set(1, rootData);
            % % %
            
        end
        
    end
    
    
    
    
    methods(Static)
        function plot_positionVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.position;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('position');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
    end
    
end
