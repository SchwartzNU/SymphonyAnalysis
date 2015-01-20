classdef BarsMultiAngleAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = BarsMultiAngleAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': BarsMultiAngleAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
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
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
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
            
            %OSI, OSang
            rootData = obj.get(1);
            rootData = addOSI(rootData, 'barAngle');
            rootData.stimParameterList = {'barAngle'};
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            obj = obj.set(1, rootData);
        end
        
    end
    
    methods(Static)
        
        function plot_barAngleVsspikeCount_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_stimInterval (' yField.units ')']);
            
        end
        
        function plot_barAngleVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['ONSETspikes (' yField.units ')']);
            
            hold on;
            x = [rootData.ONSETspikes_OSang,rootData.ONSETspikes_OSang];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.ONSETspikes_OSI) ', OSang = ' num2str(rootData.ONSETspikes_OSang)]);
            hold off;
        end
        
        function plot_barAngleVsOFFSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.OFFSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['OFFSETspikes (' yField.units ')']);
            
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['OFFSETspikes (' yField(1).units ')']);
            
            hold on;
            x = [rootData.OFFSETspikes_OSang,rootData.OFFSETspikes_OSang];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.OFFSETspikes_OSI) ', OSang = ' num2str(rootData.OFFSETspikes_OSang)]);
            hold off;
        end
        
        function plot_barAngleVsONSET_peak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSET_peak;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['ONSET_peak (' yField.units ')']);
            
            hold on;
            x = [rootData.ONSET_peak_OSang,rootData.ONSET_peak_OSang];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.ONSET_peak_OSI) ', OSang = ' num2str(rootData.ONSET_peak_OSang)]);
            hold off;
        end
        
        function plot_barAngleVsOFFSET_peak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.OFFSET_peak;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['OFFSET_peak (' yField.units ')']);
            
            hold on;
            x = [rootData.OFFSET_peak_OSang,rootData.OFFSET_peak_OSang];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.OFFSET_peak_OSI) ', OSang = ' num2str(rootData.OFFSET_peak_OSang)]);
            hold off;
        end

        function plot_barAngleVsspikeCount_ONSET_400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_ONSET_400ms;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_ONSET_400ms (' yField.units ')']);
        end
        
        function plot_barAngleVsONSET_charge400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSET_charge400ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['ONSET_charge400ms (' yField.units ')']);
        end
    end
    
end