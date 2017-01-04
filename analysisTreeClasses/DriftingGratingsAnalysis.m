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
            obj = obj.buildCellTree(1, cellData, dataSet, {'contrast','temporalFreq', 'spatialFreq','gratingAngle'});
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
            %rootData = addDSIandOSI(rootData, 'gratingAngle');
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
            ax = gca;
            for i=1:L
                epochInd = node.get(chInd(i)).epochID;
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    cellData.plotPSTH(epochInd, 10, rootData.deviceName, ax);
                else
                    cellData.plotMeanData(epochInd, false, [], rootData.deviceName, ax);
                end
                hold(ax, 'on');
            end
            hold(ax, 'off');
        end
        
        function plot_gratingAngleVsminCurrent(node, ~)
           rootData = node.get(1);
           xvals = rootData.gratingAngle;
           yField = rootData.minCycleAvg;
           yvals = yField.value;
           plot(xvals, yvals);
           xlabel('Grating Angle');
           ylabel(['Current (' yField.units ')']);
           
        end
        
        function plot_gratingAngleVsF0(node, ~)
            rootData = node.get(1);
            xvals = rootData.gratingAngle;
            yField = rootData.F0amplitude;
            yvals = yField.value;
           
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            hold on;
            
            polar([0 rootData.F0amplitude_DSang*pi/180], [0 (100*rootData.F0amplitude_DSI)], 'r-');
            polar([0 rootData.F0amplitude_OSang*pi/180], [0 (100*rootData.F0amplitude_OSI)], 'g-');
            xlabel('Grating Angle');
            ylabel(['F0 amplitude (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'F1amplitude')
            hold off;
        end
        
        function plot_gratingAngleVsF1(node, ~)
            rootData = node.get(1);
            xvals = rootData.gratingAngle;
            yField = rootData.F1amplitude;
            yvals = yField.value;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            hold on;
            polar([0 rootData.F1amplitude_DSang*pi/180], [0 (100*rootData.F1amplitude_DSI)], 'r-');
            polar([0 rootData.F1amplitude_OSang*pi/180], [0 (100*rootData.F1amplitude_OSI)], 'g-');
            xlabel('gratingAngle');
            ylabel(['F1 (' yField(1).units ')']);
            addDsiOsiVarTitle(rootData, 'F1amplitude')
            hold off;
        end
        
        function plot_gratingAngleVsF2(node, ~)
            rootData = node.get(1);
            xvals = rootData.gratingAngle;
            yField = rootData.F2amplitude;
            yvals = yField.value;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            hold on
            polar([0 rootData.F2amplitude_DSang*pi/180], [0 (100*rootData.F2amplitude_DSI)], 'r-');
            polar([0 rootData.F2amplitude_OSang*pi/180], [0 (100*rootData.F2amplitude_OSI)], 'g-');            
            xlabel('gratingAngle');
            ylabel(['F2 (' yField(1).units ')']);
            addDsiOsiVarTitle(rootData, 'F2amplitude')
        end
        
        function plot_gratingAngleVsF2overF1(node, ~)
            rootData = node.get(1);
            xvals = rootData.gratingAngle;
            yField = rootData.F2overF1;
            yvals = yField.value;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            hold on
            polar([0 rootData.F2overF1_DSang*pi/180], [0 (20*rootData.F2overF1_DSI)], 'r-');
            polar([0 rootData.F2overF1_OSang*pi/180], [0 (20*rootData.F2overF1_OSI)], 'g-');            
            xlabel('gratingAngle');
            ylabel('F2 over F1');
            addDsiOsiVarTitle(rootData, 'F2overF1')
        end
         
        function plotLeaf(node, ~)
            leafData = node.get(1);
            xField = leafData.cycleAvg_x;
            xvals = xField.value;
            yField = leafData.cycleAvg_y;
            yvals = yField.value;
            plot (xvals,yvals);
            xlabel('Time (s)');
            ylabel('Current (pA)');
        end
       
    end
end

