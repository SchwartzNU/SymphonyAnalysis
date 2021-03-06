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
        
            nameStr = [cellData.savedFileName ': ' dataSetName ': ObjectMotionSensitivityAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY', 'ampHoldSignal'});
            %obj = obj.buildCellTree(1, cellData, dataSet, {@(epoch)movementCategory(epoch)});
            obj = obj.buildCellTree(1, cellData, dataSet, {'motionMode'});
        
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
        function plot_spikeCount_stimAfter1000ms(node, cellData)
            rootData = node.get(1);
            yField = rootData.spikeCount_stimAfter1000ms;
            yvals = yField.mean_c;
            errs = yField.SEM;
            
            movementTypes = {'Center', 'Surround', 'Global', 'Differential', 'No movement'};
            moveInd = cell2mat(rootData.movementCategory);
            xvals = movementTypes(moveInd);
            
            bar(categorical(xvals), yvals)
            hold on
            errorbar(categorical(xvals), yvals, errs, 'o');
            ylabel(['Spike Count stimAfter1000ms (' yField.units ')']);
            
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
        
        function plot_spikeRate_objectMovement(node, cellData)
            rootData = node.get(1);
            yField = rootData.spikeRate_objectMovement;
            yvals = yField.mean_c;
            errs = yField.SEM;
            
            movementTypes = {'Center', 'Surround', 'Global', 'Differential', 'No movement'};
            moveInd = cell2mat(rootData.movementCategory);
            xvals = movementTypes(moveInd);
            
            bar(categorical(xvals), yvals)
            hold on
            errorbar(categorical(xvals), yvals, errs, 'o');
            ylabel(['Spike Count stimAfter1000ms (' yField.units ')']);
            
            titleString = {};
            
            if any(strcmp(xvals, 'Center')) && any(strcmp(xvals, 'Global'))
                center = yvals(find(strcmp(xvals, 'Center')));
                Global = yvals(find(strcmp(xvals, 'Global')));
                SI = (center - Global) / (center + Global);
                titleString = [titleString,'SI = ' + string(SI)];                
            end
            
            if any(strcmp(xvals, 'Differential')) && any(strcmp(xvals, 'Global'))
                diff = yvals(find(strcmp(xvals, 'Differential')));
                Global = yvals(find(strcmp(xvals, 'Global')));
                OMSI = (diff - Global) / (diff + Global);
                titleString = [titleString,'OMSI = ' + string(OMSI)];                
            end            
            
            title(titleString) 
        end
    end
end
    
