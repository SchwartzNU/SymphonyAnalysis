classdef ContrastRespAnalysis < AnalysisTree
    properties
        
    end
    
    methods
        function obj = ContrastRespAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': ContrastRespAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam, 'spotSize', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'contrast'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c;
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'contrast');
            
            %baseline subtraction and normalization (factor out in the
            %future?
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                %baseline subtraction
                grandBaselineMean = mean(baseline);
                stimTime_s = cellData.epochs(leafIDs(1)).get('stimTime')*1e-3;
                
                for i=1:L %for each leaf node
                    curNode = obj.get(leafIDs(i));
                    
                    tempStruct.ONSETrespRate_grandBaselineSubtracted = curNode.ONSETrespRate;
                    tempStruct.ONSETrespRate_grandBaselineSubtracted.value = curNode.ONSETrespRate.value - grandBaselineMean;
                    tempStruct.spikeCount_stimInterval_grandBaselineSubtracted = curNode.spikeCount_stimInterval;
                    tempStruct.spikeCount_stimInterval_grandBaselineSubtracted.value = curNode.spikeCount_stimInterval.value - grandBaselineMean; %assumes 1 sec stimInterval
                    tempStruct.OFFSETrespRate_grandBaselineSubtracted = curNode.OFFSETrespRate;
                    tempStruct.OFFSETrespRate_grandBaselineSubtracted.value = curNode.OFFSETrespRate.value - grandBaselineMean;
                    tempStruct.ONSETspikes_grandBaselineSubtracted = curNode.ONSETspikes;
                    tempStruct.ONSETspikes_grandBaselineSubtracted.value = curNode.ONSETspikes.value - grandBaselineMean.*curNode.ONSETrespDuration.value; %fix nan and INF here
                    tempStruct.OFFSETspikes_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*curNode.OFFSETrespDuration.value;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted = curNode.spikeCount_ONSET_400ms;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted.value = curNode.spikeCount_ONSET_400ms.value - grandBaselineMean.*0.4; 
                    tempStruct.ONSETspikes_200ms_grandBaselineSubtracted = curNode.spikeCount_ONSET_200ms;
                    tempStruct.ONSETspikes_200ms_grandBaselineSubtracted.value = curNode.spikeCount_ONSET_200ms.value - grandBaselineMean.*0.2; 
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*0.4;
                    tempStruct.ONSETspikes_after200ms_grandBaselineSubtracted = curNode.spikeCount_ONSET_after200ms;
                    tempStruct.ONSETspikes_after200ms_grandBaselineSubtracted.value = curNode.spikeCount_ONSET_after200ms.value - grandBaselineMean.*0.8; %assumes 1 sec stim interval
                    tempStruct = getEpochResponseStats(tempStruct);
                    tempStruct.spikeCount_stimInterval_grndBlSubt = curNode.spikeCount_stimInterval;
                    tempStruct.spikeCount_stimInterval_grndBlSubt.value = curNode.spikeCount_stimInterval.value - grandBaselineMean*stimTime_s;
                    
                    tempStruct = getEpochResponseStats(tempStruct);
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
                
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            %             toNormList = {...
            %                 'ONSETrespRate_grandBaselineSubtracted', 'OFFSETrespRate_grandBaselineSubtracted', ...
            %                 'ONSETspikes_grandBaselineSubtracted', 'OFFSETspikes_grandBaselineSubtracted', ...
            %                 'ONSETrespRate', 'OFFSETrespRate', ...
            %                 'ONSETspikes', 'OFFSETspikes', ...
            %                 'ONSET_FRmax', 'OFFSET_FRmax', ...
            %                 'ONSETpeakInstantaneousFR', 'OFFSETpeakInstantaneousFR', ...
            %                 };
            %
            %             %normalization
            %             curNode = addNormalizedFields(curNode, toNormList);
            %
            %             for i=1:length(toNormList)
            %                toNormList{i} = [toNormList{i} '_norm'];
            %             end
            %
            %             [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            %             obj = obj.percolateUp(leafIDs, toNormList, toNormList);
            
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'contrast'};
            
            rootData = addLinearInterpToCR(rootData);  
            %rootData = addSpapsFit(rootData);  
            
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
        
        function plot_contrastVsspikeCount_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField(1).units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval (' yField.units ')']);
        end
        
        function plot_contrastVsspikeCount_stimInterval_baselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval_baselineSubtracted;
            if strcmp(yField(1).units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField.units ')']);
        end
        
        function plot_contrastVsspikeCount_ONSET_after200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_ONSET_after200ms;
            if strcmp(yField(1).units, 's')
                
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_ONSET_after200ms (' yField.units ')']);
        end
  
        function plot_contrastVsONSETspikes_after200ms_grandBaselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETspikes_after200ms_grandBaselineSubtracted;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['ONSETspikes_after200ms_grandBaselineSubtracted (' yField.units ')']);
        end
        
        function plot_contrastVsspikeCount_ONSET_400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_ONSET_400ms;
            if strcmp(yField(1).units, 's')
                
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_ONSET_400ms (' yField.units ')']);
        end
        
        function plot_contrastVsspikeCount_ONSET_200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_ONSET_200ms;
            if strcmp(yField(1).units, 's')
                
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_ONSET_200ms (' yField.units ')']);
        end
        
        function plot_contrastVsONSETspikes_200ms_grandBaselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETspikes_200ms_grandBaselineSubtracted;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['ONSETspikes_200ms_grandBaselineSubtracted (' yField.units ')']);
        end
        
        function plot_contrastVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('contrast');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
        end
        
        function plot_contrastVsONSET_chargeT25(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSET_chargeT25;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['ONSET_chargeT25 (' yField.units ')']);
        end
        
        function plot_contrastVsONSETsuppressionTime(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETsuppressionTime;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('contrast');
            ylabel(['ONSETsuppressionTime (' yField.units ')']);
        end
        
        function plot_contrastVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_contrastVsONSETsuppressedSpikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETsuppressedSpikes;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('contrast');
            ylabel(['ONSETsuppressedSpikes (' yField.units ')']);
        end
        
        function plot_contrastVsONSET_respIntervalT25(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSET_respIntervalT25;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('contrast');
            ylabel(['ONSET_respIntervalT25 (' yField.units ')']);
        end
        ONSETlatency
        
        function plot_contrastVsONSETlatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETlatency;
            yvals = yField.mean;
            plot(xvals, yvals, 'bx-');
            xlim([min(xvals), max(xvals)]);
            xlabel('contrast');
            ylabel(['ONSET_ONSETlatency (' yField.units ')']);
        end        
        
        
        function plotData(node, cellData)
            rootData = node.get(1);
            errorbar(rootData.contrast, rootData.respMean, rootData.respSEM);
            xlabel('Contrast');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Spike count (norm)');
            else
                ylabel('Charge (pC)');
            end
        end
        
        function plot_contrastVsONSETspikes_grandBaselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSETspikes_grandBaselineSubtracted;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['ONSETspikes_grandBaselineSubtracted (' yField.units ')']);
        end

        function plot_contrastVsspikeCount_stimInt_gblSubt(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval_grndBlSubt;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);

            hold('on');
            xfit = min(xvals):0.02:max(xvals);
            %yfit = Heq(blurRootData.beta, xfit);
            yfit = feval(rootData.fitresult, xfit);
            plot(xfit,yfit);

            plot(rootData.onCrossing,feval(rootData.fitresult,rootData.onCrossing),'o');
            plot(rootData.onCrossingSup,feval(rootData.fitresult,rootData.onCrossingSup),'o');
            plot(rootData.offCrossing,feval(rootData.fitresult,rootData.offCrossing),'o');
            plot(rootData.offCrossingSup,feval(rootData.fitresult,rootData.offCrossingSup),'o');
            
            hold('off');
        end
        
         function plot_contrastVsspikeCount_stimInt_gblSubtNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
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
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
         end
        
    end
    
end