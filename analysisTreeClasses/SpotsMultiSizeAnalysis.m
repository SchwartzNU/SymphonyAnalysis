classdef SpotsMultiSizeAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 1000;
    end
    
    methods
        function obj = SpotsMultiSizeAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': SpotsMultiSizeAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY', 'ampHoldSignal'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'curSpotSize'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);  %for grandBaseline subt. Adam 2/17/13
            
            %get grand mean for multi-peak fitting (with zero crossings)
            %             if strcmp(rootData.(rootData.ampModeParam), 'Whole cell')
            %                 allEpochIDs = [];
            %                 lowPassFreq = 10;
            %
            %                 for i=1:L %for each leaf node
            %                     curNode = obj.get(leafIDs(i));
            %                     allEpochIDs = [allEpochIDs, curNode.epochID];
            %                 end
            %                 [dataMean, xvals] = cellData.getMeanData(allEpochIDs, rootData.deviceName);
            %
            %                 %multiple peaks from zero crossings
            %                 [zeroCrossings, directions] = findZeroCrossings(dataMean, xvals, obj.EndTime*1E-3, lowPassFreq, 1E-4);
            %                 for i=1:length(zeroCrossings)
            %
            %
            %                 end
            %
            %                 zeroCrossings = [zeroCrossings getThresCross(xvals, obj.EndTime*1E-3, 1)]; %add end time to get last peak;
            %                 directions = [directions, 0];
            %                 zeroCrossings(1) = getThresCross(xvals, 0, 1); %replace first zero crossing with stim start
            %                 zeroCrossings(2) = getThresCross(xvals, 0.14, 1); %temp hack
            %
            %                 Npeaks = length(zeroCrossings)-1;
            %                 if Npeaks > 1
            %                     crossingParam = [zeroCrossings; directions]
            %                 else
            %                     crossingParam = [];
            %                 end
            %                 %keyboard;
            %             end
            
            
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'FitPSTH', 0);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c; %for grandBaseline subt. Adam 2/17/13
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    %'ZeroCrossingPeaks', crossingParam);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'spotSize');
            
            %grand baseline subtraction Adam 2/17/13
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
 
                
                grandBaselineMean = mean(baseline);
                for i=1:L %for each leaf node
                    curNode = obj.get(leafIDs(i));
                    
                    
                    tempStruct.spikeCount_ONSET_after200ms_grndBlSubt = curNode.spikeCount_ONSET_after200ms;
                    tempStruct.spikeCount_ONSET_after200ms_grndBlSubt.value = curNode.spikeCount_ONSET_after200ms.value - grandBaselineMean.*0.8; %assumes 1 sec stim interval
                    tempStruct.spikeCount_stimInterval_grndBlSubt = curNode.spikeCount_stimInterval;
                    tempStruct.spikeCount_stimInterval_grndBlSubt.value = curNode.spikeCount_stimInterval.value - grandBaselineMean; %assumes 1 sec stim interval
                    tempStruct = getEpochResponseStats(tempStruct);
                    
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            %fnames = fnames{1};
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            %  %Meta-analysis parameters - curve fits, normalization, interpolation, etc
            
            %                 metaAnalysisParamList = {
            %                     'meanONenhancedSpikes';
            %                     'meanOFFenhancedSpikes';
            %                     'meanONpeakFR';
            %                     'meanOFFpeakFR'
            %                     };
            %
            %                 numParamsMeta = length(metaAnalysisParamList);
            %                 rootData = obj.get(1);
            %                 spotSize = rootData.spotSize;
            %                 for paramInd = 1:numParamsMeta
            %                     paramName = metaAnalysisParamList{paramInd};
            %
            %                     eval(['tempParamVariable = rootData.', paramName,';']);
            %
            %                     [maxVal, maxInd] = max(tempParamVariable);
            %                     Xmax = spotSize(maxInd);
            %                     infVal = mean(tempParamVariable(end-2: end)); %"asymptotic" value.
            %                     YinfOverYmax = infVal/maxVal;
            %
            %                     halfMaxLeftInd = find(tempParamVariable > maxVal/2, 1, 'first');
            %                     halfMaxRightInd = find(tempParamVariable > maxVal/2, 1, 'last');
            %                     Xwidth = spotSize(halfMaxRightInd) - spotSize(halfMaxLeftInd);  %This is a wrong metric, have to extrapolate.
            %
            %                     eval(['rootData.',paramName,'_Xmax = Xmax;']);
            %                     eval(['rootData.',paramName,'_YinfOverYmax = YinfOverYmax;']);
            %                     eval(['rootData.',paramName,'_Xwidth = Xwidth;']);
            %                 end;
            
            %to add more here
            rootData = obj.get(1);
            % Adam 2/25/17
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                rootData = addWidthScalars(rootData, 'spotSize', {'spikeCount_stimInterval_grndBlSubt'});
                rootData = addWidthScalars(rootData, 'spotSize',{'spikeCount_stimInterval_grndBlSubt'}, 'fixedVal',1200);
                rootData = addWidthScalars(rootData, 'spotSize',{'spikeCount_stimInterval_grndBlSubt'}, 'fixedVal',600);
                supression1200 = 1-(rootData.spikeCount_stimInterval_grndBlSubt_spotSizeFixed1200/...
                    rootData.spikeCount_stimInterval_grndBlSubt_spotSizeByMax);
                rootData.spikeCount_stimInterval_grndBlSubt_SMSsupression1200 = supression1200;
                supression600 = 1-(rootData.spikeCount_stimInterval_grndBlSubt_spotSizeFixed600/...
                    rootData.spikeCount_stimInterval_grndBlSubt_spotSizeByMax);
                rootData.spikeCount_stimInterval_grndBlSubt_SMSsupression600 = supression600;
                
                %Adam 4/21/17
                rootData = addSumOfGaussFit(rootData);
            end;
            % End Adam 2/25/17
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'spotSize'};
            obj = obj.set(1, rootData);
            % % %
            
        end
        
    end
    
    
    
    
    methods(Static)
        
        function plot0_spotSizeVsspikeCounts_beforeAndAfterStim(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs, 'c');
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref On Size: %g µm', bestSize));                
            
            yField = rootData.spikeCount_afterStim;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            hold on
            errorbar(xvals, yvals, errs, 'k');            
            hold off
            
            xlabel('spotSize');
            ylabel(['spikeCount_stimIntervals (' yField.units ')']);
        end
        
        
        function plot1_spotSizeVsspikeCount_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['spikeCount_stimInterval (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
        
        function plot2_spotSizeVsspikeCount_afterStim(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_afterStim;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['spikeCount_afterStim (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
                
        
        function plot_spotSizeVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['ONSETspikes (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
        
        function plot_spotSizeVsOFFSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.OFFSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['OFFSETspikes (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
        function plot_spotSizeVsONSET_peak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_peak;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['ONSET_peak (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
        
        function plot_spotSizeVsONSETsuppressedSpikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETsuppressedSpikes;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSETsuppressedSpikes (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSETsuppressionTime(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETsuppressionTime;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSETsuppressionTime (' yField.units ')']);
        end
        
        function plotEpochData(node, cellData, device, epochIndex)
            nodeData = node.get(1);
            cellData.epochs(nodeData.epochID(epochIndex)).plotData(device);
            title(['Epoch # ' num2str(nodeData.epochID(epochIndex)) ': ' num2str(epochIndex) ' of ' num2str(length(nodeData.epochID))]);
            if strcmp(device, 'Amplifier_Ch1')
                spikesField = 'spikes_ch1';
            else
                spikesField = 'spikes_ch2';
            end
            spikeTimes = cellData.epochs(nodeData.epochID(epochIndex)).get(spikesField);
            if ~isnan(spikeTimes)
                [data, xvals] = cellData.epochs(nodeData.epochID(epochIndex)).getData(device);
                hold('on');
                plot(xvals(spikeTimes), data(spikeTimes), 'rx');
                hold('off');
            end
            
            ONendTime = cellData.epochs(nodeData.epochID(epochIndex)).get('stimTime')*1E-3; %s
            ONstartTime = 0;
            if isfield(nodeData, 'ONSETlatency') && ~isnan(nodeData.ONSETlatency.value(1))
                %draw lines here
                hold on
                firingStart = node.get(1).ONSETlatency.value(epochIndex)+ONstartTime;
                firingEnd = firingStart + node.get(1).ONSETrespDuration.value(epochIndex);
                burstBound = firingStart + node.get(1).ONSETburstDuration.value(epochIndex);
                upperLim = max(data)+50;
                lowerLim = min(data)-50;
                plot([firingStart firingStart], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
                plot([firingEnd firingEnd], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
                plot([burstBound burstBound], [upperLim lowerLim], 'LineStyle','--');
                hold off
            end
            if isfield(nodeData, 'OFFSETlatency') && ~isnan(nodeData.OFFSETlatency.value(1))
                %draw lines here
                hold on
                firingStart = node.get(1).OFFSETlatency.value(epochIndex)+ONendTime;
                firingEnd = firingStart + node.get(1).OFFSETrespDuration.value(epochIndex);
                burstBound = firingStart + node.get(1).OFFSETburstDuration.value(epochIndex);
                upperLim = max(data)+50;
                lowerLim = min(data)-50;
                plot([firingStart firingStart], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
                plot([firingEnd firingEnd], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
                plot([burstBound burstBound], [upperLim lowerLim], 'LineStyle','--');
                hold off
            end
            
        end
        
        function plot_spotSizeVsONSET_FRhalfMaxLatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_FRhalfMaxLatency;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_FRhalfMaxLatency (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_FRmax(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_FRmax;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_FRmax (' yField.units ')']);
        end
        
        function plot_spotSizeVsstimInterval_charge(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.stimInterval_charge;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['stimInterval_charge (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
        
        function plot_spotSizeVsstimInterval_chargeNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.stimInterval_charge;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            [M, Mind] = max(abs(yvals));
            if yvals(Mind) < 0 
                yvals = -yvals./M;
            else
                yvals = yvals./M;
            end;
            errs = errs./M;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['stimInterval_charge (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
            [~,i] = max(yvals);
            bestSize = xvals(i);
            title(sprintf('Pref Size: %g µm', bestSize));            
        end
        
        function plot_spotSizeVsspikeCount_stimInterval_baselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_stimInterval_baselineSubtracted;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_FRhalfMaxSusLatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_FRhalfMaxSusLatency;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_FRhalfMaxSusLatency (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_FRhalfMaxSusLatency20(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_FRhalfMaxSusLatency20;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_FRhalfMaxSusLatency (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_FRhalfMaxSusLatency_inXlimits(node, cellData)
            xRangeMin = 180;
            xRangeMax = 700;
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_FRhalfMaxSusLatency;
            yvals = yField.value;
            xvalsNew = xvals((xvals>=xRangeMin)&(xvals<=xRangeMax));
            yvalsNew = yvals((xvals>=xRangeMin)&(xvals<=xRangeMax));
            plot(xvalsNew, yvalsNew, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_FRhalfMaxSusLatency (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSETspikesNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETspikes;
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
            xlabel('spotSize');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSETspikesNORM_inXlimits(node, cellData)
            xRangeMin = 180;
            xRangeMax = 700;
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            M = max(abs(yvals));
            yvals = yvals./M;
            errs = errs./M;
            xvalsNew = xvals((xvals>=xRangeMin)&(xvals<=xRangeMax));
            yvalsNew = yvals((xvals>=xRangeMin)&(xvals<=xRangeMax));
            errsNew = errs((xvals>=xRangeMin)&(xvals<=xRangeMax));
            errorbar(xvalsNew, yvalsNew, errsNew);
            xlabel('spotSize');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_spotSizeVsstimToEnd_respIntervalT25(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.stimToEnd_respIntervalT25;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['ONSET_respIntervalT25 (' yField.units ')']);
        end
        
        function plot_spotSizeVsstimToEnd_respIntervalT50(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.stimToEnd_respIntervalT50;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['stimToEnd_respIntervalT50 (' yField.units ')']);
        end
        
        function plot_spotSizeVsstimToEnd_avgTrace_latencyToT50(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.stimToEnd_avgTrace_latencyToT50;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['stimToEnd_avgTrace_latencyToT50 (' yField.units ')']);
        end
        
        function plot_spotSizeVsstimToEnd_avgTrace_latencyToT25(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.stimToEnd_avgTrace_latencyToT25;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('spotSize');
            ylabel(['stimToEnd_avgTrace_latencyToT25 (' yField.units ')']);
        end
        
        function plot_spotSizeVsspikeCount_stimTo200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_stimTo200ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['spikeCount_stimTo200ms (' yField.units ')']);
        end
        
        function plot_spotSizeVsspikeCount_stimAfter200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_stimAfter200ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['spikeCount_stimAfter200ms (' yField.units ')']);
        end

        function plot_spotSizeVsspikeCount_stimInt_gblSubt(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.spikeCount_stimInterval_grndBlSubt;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs, '.');
            xlabel('spotSize');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']); 
            
            hold('on');
            xfit = min(xvals):max(xvals);
            yfit = feval(rootData.fitresult, xfit);
            plot(xfit,yfit);
            plot(rootData.fitMax,feval(rootData.fitresult,rootData.fitMax),'o');
            hold('off');

        end
        
         function plot_spotSizeVsspikeCount_stimInt_gblSubtNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
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
            xlabel('spotSize');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
         end
         
         function plot_spotSizeVsstimAfter200_charge(node, cellData)
             rootData = node.get(1);
             xvals = rootData.spotSize;
             yField = rootData.stimAfter200_charge;
             if strcmp(yField.units, 's')
                 yvals = yField.median_c;
             else
                 yvals = yField.mean_c;
             end
             errs = yField.SEM;
             errorbar(xvals, yvals, errs);
             xlabel('spotSize');
             ylabel(['stimAfter200_charge (' yField.units ')']);
         end
       
         
        function plot_spotSizeVsOFFSET_peak400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.OFFSET_peak400ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['OFFSET_peak400ms (' yField.units ')']);
        end
        
        function plot_spotSizeVsOFFSET_charge400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.OFFSET_charge400ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['OFFSET_charge400ms (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_peak400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_peak400ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['ONSET_peak400ms (' yField.units ')']);
        end
        
        function plot_spotSizeVsONSET_charge400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSET_charge400ms;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('spotSize');
            ylabel(['ONSET_charge400ms (' yField.units ')']);
        end
        
        
        function plot_spotSizeVsONSETrespDuration(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETrespDuration;
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
            xlabel('spotSize');
            ylabel(['ONSETrespDuration (' yField.units ')']);
        end        
        
      
        
        function plot_spotSizeVsONSETlatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.ONSETlatency;
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
            xlabel('spotSize');
            ylabel(['ONSETlatency (' yField.units ')']);
        end    
        
        function plot_spotSizeVsOFFSETrespDuration(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.OFFSETrespDuration;
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
            xlabel('spotSize');
            ylabel(['OFFSETrespDuration (' yField.units ')']);
        end        
        
      
        
        function plot_spotSizeVsOFFSETlatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.spotSize;
            yField = rootData.OFFSETlatency;
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
            xlabel('spotSize');
            ylabel(['OFFSETlatency (' yField.units ')']);
        end         
    end
    
end
