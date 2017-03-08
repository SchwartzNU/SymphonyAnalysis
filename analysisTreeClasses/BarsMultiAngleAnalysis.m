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
            baseline = zeros(1,L);  %for grandBaseline subt.
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c; %for grandBaseline subt. Adam 2/13/17
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
                    baselineMean = outputStruct.baselineRate.mean_c; %THIS WAS WRONGLY NAMED "GRAND_BASELINE" Adam 2/13/17
                    tempStruct.ONSETrespRate_baselineSubtracted = curNode.ONSETrespRate;
                    tempStruct.ONSETrespRate_baselineSubtracted.value = curNode.ONSETrespRate.value - baselineMean;
                    tempStruct.OFFSETrespRate_baselineSubtracted = curNode.OFFSETrespRate;
                    tempStruct.OFFSETrespRate_baselineSubtracted.value = curNode.OFFSETrespRate.value - baselineMean;
                    tempStruct.ONSETspikes_baselineSubtracted = curNode.ONSETspikes;
                    tempStruct.ONSETspikes_baselineSubtracted.value = curNode.ONSETspikes.value - baselineMean.*curNode.ONSETrespDuration.value; %fix nan and INF here
                    tempStruct.OFFSETspikes_baselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_baselineSubtracted.value = curNode.OFFSETspikes.value - baselineMean.*curNode.OFFSETrespDuration.value;
                    tempStruct.ONSETspikes_400ms_baselineSubtracted = curNode.spikeCount_ONSET_400ms;
                    tempStruct.ONSETspikes_400ms_baselineSubtracted.value = curNode.spikeCount_ONSET_400ms.value - baselineMean.*0.4; %fix nan and INF here
                    tempStruct.OFFSETspikes_400ms_baselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_400ms_baselineSubtracted.value = curNode.OFFSETspikes.value - baselineMean.*0.4;
                    tempStruct = getEpochResponseStats(tempStruct);
                    
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
                
                grandBaselineMean = mean(baseline);
                for i=1:L %for each leaf node
                    curNode = obj.get(leafIDs(i));
                    
                    tempStruct.spikeCount_stimInterval_grndBlSubt = curNode.spikeCount_stimInterval;
                    tempStruct.spikeCount_stimInterval_grndBlSubt.value = curNode.spikeCount_stimInterval.value - grandBaselineMean; %assumes 1 sec stim interval
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
            ind = find(rootData.barAngle >= 180);
            rootData.barAngle(ind) = rootData.barAngle(ind) - 180;   
            rootData = addOSI(rootData, 'barAngle');
            rootData.stimParameterList = {'barAngle'};
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            obj = obj.set(1, rootData);
            
            % Fitting FB curves to 2 cosine waves - David 3-3-17
            rootData = obj.get(1);
            rootData = AddCosFit(rootData);
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
        
        function plot_barAngleVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('barAngle');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
            
            hold on;
            x = [rootData.ONSET_avgTracePeak_OSang,rootData.ONSET_avgTracePeak_OSang];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.ONSET_avgTracePeak_OSI) ', OSang = ' num2str(rootData.ONSET_avgTracePeak_OSang)]);
            hold off;
        end
        
        function plot_barAngleVsspikeCount_stimInterval_baselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimInterval_baselineSubtracted;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField.units ')']);
            
            hold on;
            x = [rootData.spikeCount_stimInterval_baselineSubtracted,rootData.spikeCount_stimInterval_baselineSubtracted];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.spikeCount_stimInterval_baselineSubtracted_OSI) ', OSang = ' num2str(rootData.spikeCount_stimInterval_baselineSubtracted_OSang)]);
            hold off;
        end
        
        function plot_barAngleVsspikeCount_stimTo200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimTo200ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_stimTo200ms (' yField.units ')']);
            
            hold on;
            x = [rootData.spikeCount_stimTo200ms,rootData.spikeCount_stimTo200ms];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.spikeCount_stimTo200ms_OSI) ', OSang = ' num2str(rootData.spikeCount_stimTo200ms_OSang)]);
            hold off;
        end
        
        function plot_barAngleVsspikeCount_stimAfter200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimAfter200ms;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_stimAfter200ms (' yField.units ')']);
            
            hold on;
            x = [rootData.spikeCount_stimAfter200ms,rootData.spikeCount_stimAfter200ms];
            y = get(gca, 'ylim');
            plot(x,y);
            title(['OSI = ' num2str(rootData.spikeCount_stimAfter200ms_OSI) ', OSang = ' num2str(rootData.spikeCount_stimAfter200ms_OSang)]);
            hold off;
        end
       function plot_barAngleVsspikeCount_stimInt_gblSubt(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimInterval_grndBlSubt;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
            
            hold on
            xvals2 = 1:180;
            yvals2 = TwoCos(rootData.spikeCount_stimInterval_grndBlSubt.beta,xvals2);
            plot(xvals2, yvals2);
            
            beta1 = num2str(rootData.spikeCount_stimInterval_grndBlSubt.beta(1));
            beta2 = num2str(rootData.spikeCount_stimInterval_grndBlSubt.beta(2));
            beta3 = num2str(rootData.spikeCount_stimInterval_grndBlSubt.beta(3));
            beta4 = num2str(rootData.spikeCount_stimInterval_grndBlSubt.beta(4));
            beta5 = num2str(rootData.spikeCount_stimInterval_grndBlSubt.beta(5));
            title(['f(x) = ' beta1 ' + ' beta2 'cos(2(x - ' beta3 ')) + ' beta4 'cos(4(x - ' beta5 '))']);
            hold off;
            function y = TwoCos(beta,x)

                y = beta(1) + beta(2)*cosd(2*(x - beta(3))) + beta(4)*cosd(4*(x - beta(5)));

            end
        end
        
        function plot_barAngleVsspikeCount_stimInt_gblSubtNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.barAngle;
            yField = rootData.spikeCount_stimInterval_grndBlSubt;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            M = max(abs(yvals));
            yvals = yvals./M;
            errs = errs./M;
            errorbar(xvals, yvals, errs);
            xlabel('barAngle');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted_norm (' yField.units ')']);
        end 
        
    end
    
end