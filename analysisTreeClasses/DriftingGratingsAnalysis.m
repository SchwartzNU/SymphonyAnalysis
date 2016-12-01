classdef DriftingGratingsAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    
    methods
        function obj = DriftingGratingsAnalysis(cellData, dataSetName, params)
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
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': DriftingGratingsAnalysis'];            
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam, 'gratingProfile', 'contrast', 'offsetX', 'offsetY'});
%             obj = obj.buildCellTree(1, cellData, dataSet, {'contrast','temporalFreq', 'spatialFreq','gratingAngle'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'gratingAngle'});
        end
        
        function obj = doAnalysis(obj, cellData)
           rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_gratings_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'BaselineTime', 200);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_gratings_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'BaselineTime',50);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'gratingAngle');

            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            spatialFreqLevelNodes = getTreeLevel(obj, 'spatialFreq');
            for i=1:length(spatialFreqLevelNodes)
                nodeData = obj.get(spatialFreqLevelNodes(i));
                nodeData = addDSIandOSI(nodeData, 'gratingAngle');
                nodeData.stimParameterList = {'gratingAngle'};  
                nodeData.byEpochParamList = byEpochParamList;
                nodeData.singleValParamList = singleValParamList;
                nodeData.collectedParamList = collectedParamList;
                obj = obj.set(spatialFreqLevelNodes(i), nodeData); 
            end
            
            %OSI, OSang
            rootData = obj.get(1);
            rootData = addDSIandOSI(rootData, 'gratingAngle');
            %rootData.stimParameterList = {'gratingAngle'};
            %rootData.byEpochParamList = byEpochParamList;
            %rootData.singleValParamList = singleValParamList;
            %rootData.collectedParamList = collectedParamList;
            obj = obj.set(1, rootData);   
        end
    end
    
    methods(Static)
        
        function plotMeanTraces(node, cellData)
            rootData = node.get(1);
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = axes;
            for i=1:L
                hold(ax, 'on');
                epochInd = node.get(chInd(i)).epochID;
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    cellData.plotPSTH(epochInd, 10, rootData.deviceName, ax);
                else
                    cellData.plotMeanData(epochInd, false, [], rootData.deviceName, ax);
                end
            end
            hold(ax, 'off');
        end
        
        function plot_gratingAngleVsF0(node, cellData)
           rootData = node.get(1);
           xvals = rootData.gratingAngle;
           yField = rootData.F0amplitude;
           yvals = yField.value;
           plot(xvals, yvals);
           xlabel('Grating Angle');
           ylabel(['F0 amplitude (' yField.units ')']);
            
           hold on;
           x = [rootData.F0amplitude_OSang,rootData.F0amplitude_OSang];
           y = get(gca, 'ylim');
           plot(x,y);
           addDsiOsiVarTitle(rootData, 'F0amplitude')
           hold off;
        end
        
        function plot_gratingAngleVsF1(node, cellData)
           rootData = node.get(1);
           xvals = rootData.gratingAngle;
           yField = rootData.F1amplitude;
           yvals = yField.value;
           polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
           hold on;
           polar([0 rootData.F1amplitude_DSang*pi/180], [0 (100*rootData.F1amplitude_DSI)], 'r-');
           polar([0 rootData.F1amplitude_OSang*pi/180], [0 (100*rootData.F1amplitude_OSI)], 'g-');
           xlabel('Grating Angle');
           ylabel(['F1 (' yField(1).units ')']);
           addDsiOsiVarTitle(rootData, 'F1amplitude')
           hold off;
        end
        
        function plot_gratingAngleVsF2(node, cellData)
           rootData = node.get(1);
           xvals = rootData.gratingAngle;
           yField = rootData.F2amplitude;
           yvals = yField.value;
           polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
           hold on;
           polar([0 rootData.F2amplitude_DSang*pi/180], [0 (100*rootData.F2amplitude_DSI)], 'r-');
           polar([0 rootData.F2amplitude_OSang*pi/180], [0 (100*rootData.F2amplitude_OSI)], 'g-');
           xlabel('Grating Angle');
           ylabel(['F2 (' yField(1).units ')']);
           addDsiOsiVarTitle(rootData, 'F2amplitude')
           hold off;
        end
        
        function plot_gratingAngleVsF2overF1(node, cellData)
            rootData = node.get(1);
            xvals = rootData.gratingAngle;
            yField = rootData.F2overF1;
            yvals = yField.value;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            xlabel('gratingAngle');
            ylabel('F2 over F1');
        end
         
        function plotLeaf(node, cellData)
            leafData = node.get(1);
            if ~isfield(leafData, 'cycleAvg_y')
                yField = leafData.cycleAvgPSTH_y;
                xField = leafData.cycleAvgPSTH_x;
            else
                yField = leafData.cycleAvg_y;
                xField = leafData.cycleAvg_x;
            end
            xvals = xField.value;
            yvals = yField.value;
            plot (xvals,yvals);
            xlabel('Time (s)');
            ylabel('Current (pA)');
        end
       
    end
end

