classdef MovingBarAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = MovingBarAnalysis(cellData, dataSetName, params)
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
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': MovingBarAnalysis'];            
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam, 'intensity', 'barLength', 'barWidth', 'distance', 'barSpeed', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'barAngle'});
        end
        
        function obj = doAnalysis(obj, cellData)
           rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'BaselineTime', 250);
                        %'FitPSTH', 2); %fit 2 peaks in PSTH
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'BaselineTime', 250);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'barAngle');
   
        %baseline subtraction and normalization (factor out in the
            %future?
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
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
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted = curNode.spikeCount_ONSET_400ms;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted.value = curNode.spikeCount_ONSET_400ms.value - grandBaselineMean.*0.4; %fix nan and INF here
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*0.4;
                    tempStruct = getEpochResponseStats(tempStruct);
                    
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
                
                
            end
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            %DSI, OSI, DSang, OSang
            rootData = obj.get(1);
            rootData = addDSIandOSI(rootData, 'barAngle');
            rootData.stimParameterList = {'barAngle'};
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            obj = obj.set(1, rootData);   

        end
    end
    
    methods(Static)
        
        function plot_barAngleVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSETspikes;
            if strcmp(yField(1).units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            polarerror(xvals*pi/180, yvals, errs);
            hold on;
            polar([0 rootData.ONSETspikes_DSang*pi/180], [0 (100*rootData.ONSETspikes_DSI)], 'r-');
            polar([0 rootData.ONSETspikes_OSang*pi/180], [0 (100*rootData.ONSETspikes_OSI)], 'g-');
            xlabel('barAngle');
            ylabel(['ONSETspikes (' yField(1).units ')']);
            addDsiOsiVarTitle(rootData, 'ONSETspikes')
            hold off;
        end
        
        function plot_barAngleVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            hold on;
            polar([0 rootData.ONSET_avgTracePeak_DSang*pi/180], [0 (100*rootData.ONSET_avgTracePeak_DSI)], 'r-');
            polar([0 rootData.ONSET_avgTracePeak_OSang*pi/180], [0 (100*rootData.ONSET_avgTracePeak_OSI)], 'g-');
            xlabel('barAngle');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'ONSET_avgTracePeak')
            hold off;
        end
        
        function plot_barAngleVsspikeCount_stimToEnd(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimToEnd;
            yvals = yField.mean_c;
            errs = yField.SEM;
            polarerror(xvals*pi/180, yvals, errs);            
            hold on;
            polar([0 rootData.spikeCount_stimToEnd_DSang*pi/180], [0 (100*rootData.spikeCount_stimToEnd_DSI)], 'r-');
            polar([0 rootData.spikeCount_stimToEnd_OSang*pi/180], [0 (100*rootData.spikeCount_stimToEnd_OSI)], 'g-');
            xlabel('barAngle');
            ylabel(['spikeCount_stimToEnd (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'spikeCount_stimToEnd')
            hold off;            
        end
        
        function plot_barAngleVsspikeCount_mbLeading(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_mbLeading;
            yvals = yField.mean_c;
            errs = yField.SEM;
            polarerror(xvals*pi/180, yvals, errs);            
            hold on;
            polar([0 rootData.spikeCount_mbLeading_DSang*pi/180], [0 (100*rootData.spikeCount_mbLeading_DSI)], 'r-');
            polar([0 rootData.spikeCount_mbLeading_OSang*pi/180], [0 (100*rootData.spikeCount_mbLeading_OSI)], 'g-');
            xlabel('barAngle');
            ylabel(['spikeCount mbLeading (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'spikeCount_mbLeading')
            hold off;            
        end
        
        function plot_barAngleVsspikeCount_mbTrailing(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_mbTrailing;
            yvals = yField.mean_c;
            errs = yField.SEM;
            polarerror(xvals*pi/180, yvals, errs);            
            hold on;
            polar([0 rootData.spikeCount_mbTrailing_DSang*pi/180], [0 (100*rootData.spikeCount_mbTrailing_DSI)], 'r-');
            polar([0 rootData.spikeCount_mbTrailing_OSang*pi/180], [0 (100*rootData.spikeCount_mbTrailing_OSI)], 'g-');
            xlabel('barAngle');
            ylabel(['spikeCount mbTrailing (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'spikeCount_mbTrailing')
            hold off;
        end
        
        function plot_barAngleVscharge_mbLeading(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.charge_mbLeading;

            yvals = yField.mean_c;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.charge_mbLeading_DSang*pi/180], [0 (100*rootData.charge_mbLeading_DSI)], 'r-');
            polar([0 rootData.charge_mbLeading_OSang*pi/180], [0 (100*rootData.charge_mbLeading_OSI)], 'g-');
            ylabel(['charge_mbLeading (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'charge_mbLeading')
            hold off;
        end        
        
        
        function plot_barAngleVscharge_mbTrailing(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.charge_mbTrailing;

            yvals = yField.mean_c;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.charge_mbTrailing_DSang*pi/180], [0 (100*rootData.charge_mbTrailing_DSI)], 'r-');
            polar([0 rootData.charge_mbTrailing_OSang*pi/180], [0 (100*rootData.charge_mbTrailing_OSI)], 'g-');
            ylabel(['charge_mbTrailing (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'charge_mbTrailing')
            hold off;
        end     
        
        function plot_barAngleVscharge_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.stimInterval_charge;

            yvals = yField.mean_c;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.stimInterval_charge_DSang*pi/180], [0 (100*rootData.stimInterval_charge_DSI)], 'r-');
            polar([0 rootData.stimInterval_charge_OSang*pi/180], [0 (100*rootData.stimInterval_charge_OSI)], 'g-');
            ylabel(['stimInterval charge (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'stimInterval_charge')
            hold off;
        end  
        
        function plot_barAngleVspeak_mbLeading(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.peak_mbLeading;

            yvals = yField.mean_c;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.peak_mbLeading_DSang*pi/180], [0 (100*rootData.peak_mbLeading_DSI)], 'r-');
            polar([0 rootData.peak_mbLeading_OSang*pi/180], [0 (100*rootData.peak_mbLeading_OSI)], 'g-');
            ylabel(['peak mbLeading (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'peak_mbLeading')
            hold off;
        end              
        
        function plot_barAngleVspeak_mbTrailing(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.peak_mbTrailing;

            yvals = yField.mean_c;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.peak_mbTrailing_DSang*pi/180], [0 (100*rootData.peak_mbTrailing_DSI)], 'r-');
            polar([0 rootData.peak_mbTrailing_OSang*pi/180], [0 (100*rootData.peak_mbTrailing_OSI)], 'g-');
            ylabel(['peak mbTrailing (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'peak_mbTrailing')
            hold off;
        end             
        

        function plot_barAngleVsONSETlatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSETlatency;

            yvals = yField.mean_c;
            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.ONSETlatency_DSang*pi/180], [0 (100*rootData.ONSETlatency_DSI)], 'r-');
            polar([0 rootData.ONSETlatency_OSang*pi/180], [0 (100*rootData.ONSETlatency_OSI)], 'g-');
            ylabel(['ONSETlatency (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'ONSETlatency')
            hold off;
        end
        
        
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
        
        
    end
end

