classdef ObjectMotionSensitivityAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = ObjectMotionSensitivityAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
        
            nameStr = [cellData.savedFileName ': ' dataSetName ': LightStepAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY', 'ampHoldSignal'});
            obj = obj.buildCellTree(1, cellData, dataSet, {@(epoch)movementCategory(epoch)});
        
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            splitParams = cell([L,1]);
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    splitParams{i} = curNode.splitValue;
                    curNode = mergeIntoNode(curNode, outputStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            rootData = obj.get(1);
            rootData.movementCategory = splitParams;
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
        function plot_movementVsSpikeCountStimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.movementCategory;
            yField = rootData.spikeCount_stimInterval;
            yvals = yField.mean_c;
            errs = yField.SEM;
            bar(categorical(xvals), yvals)
            hold on
            errorbar(categorical(xvals), yvals, errs, 'o');
            ylabel(['Spike Count Stim Interval (' yField.units ')']);
            
            titleString = {};
            
            if any(strcmp(xvals, 'Center')) && any(strcmp(xvals, 'Global'))
                centerInd = find(strcmp(xvals, 'Center'));
                globalInd = find(strcmp(xvals, 'Global'));
                globalCenterRatio = yvals(globalInd)/yvals(centerInd);
                titleString = [titleString,'Global/Center = ' + string(globalCenterRatio)];                
            end
            
            if any(strcmp(xvals, 'Differential')) && any(strcmp(xvals, 'Global'))
                DiffInd = find(strcmp(xvals, 'Differential'));
                globalInd = find(strcmp(xvals, 'Global'));
                globalDiffRatio = yvals(globalInd)/yvals(DiffInd);
                titleString = [titleString,'Global/Differential = ' + string(globalDiffRatio)];                
            end            

            title(titleString) 
        end
    end
    
end