classdef AnnulusAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 1000;
    end
    
    methods
        function obj = AnnulusAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': AnnulusAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'curInnerDiameter'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);  %for grandBaseline subt.

            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'FitPSTH', 0);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c; %for grandBaseline subt.
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
                'splitValue', 'curInnerDiameter');
            
            %grand baseline subtraction 
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                %baseline subtraction
           
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
            
            %to add more here
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'curInnerDiameter'};
            obj = obj.set(1, rootData);
            % % %
            
        end
        
    end
    
    
    
    
    methods(Static)
        
        
        function plot_innerDiameterVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSETspikes_perArea(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            
            %Find annulus area(s)
            epInd = node.get(2).epochID;
            epInd = epInd(1);
            initArea = cellData.epochs(epInd).attributes('initArea');
            initThick = cellData.epochs(epInd).attributes('initThick');
            keepConstant = cellData.epochs(epInd).attributes('keepConstant');
            if strcmp(keepConstant,'area')
                area = ones(length(xVals),1).*initArea;
            else
                curOuterDiameter = rootData.curInnerDiameter+initThick*2;
                area = pi*((curOuterDiameter./2).^2-(rootData.curInnerDiameter./2).^2);
            end;
            yvals = yvals./area;
            errs = errs./area;
            

            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['ONSETspikes/area (' yField.units '/sq. micron)']);
        end
        
        
        function plot_innerDiameterVsOFFSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.OFFSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['OFFSETspikes (' yField.units ')']);
        end
        function plot_innerDiameterVsONSET_peak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSET_peak;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['ONSET_peak (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSETsuppressedSpikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSETsuppressedSpikes;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('inner diameter');
            ylabel(['ONSETsuppressedSpikes (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSETsuppressionTime(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSETsuppressionTime;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('inner diameter');
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
            end;
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
        
        function plot_innerDiameterVsONSET_FRhalfMaxLatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSET_FRhalfMaxLatency;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('inner diameter');
            ylabel(['ONSET_FRhalfMaxLatency (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSET_FRmax(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSET_FRmax;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('inner diameter');
            ylabel(['ONSET_FRmax (' yField.units ')']);
        end
        
        function plot_innerDiameterVsstimInterval_charge(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.stimInterval_charge;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['stimInterval_charge (' yField.units ')']);
        end
        
        function plot_innerDiameterVsstimInterval_chargeNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
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
            xlabel('inner diameter');
            ylabel(['stimInterval_charge (' yField.units ')']);
        end
        
        function plot_innerDiameterVsstimInterval_chargeNORMat60(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.stimInterval_charge;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            M = yvals(xvals==60);
            yvals = yvals./M;
            errs = errs./M;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['stimInterval_charge (' yField.units ')']);
        end
        
        function plot_innerDiameterVsstimInterval_charge_perArea(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.stimInterval_charge;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            
            %Find annulus area(s)
            epInd = node.get(2).epochID;
            epInd = epInd(1);
            initArea = cellData.epochs(epInd).attributes('initArea');
            initThick = cellData.epochs(epInd).attributes('initThick');
            keepConstant = cellData.epochs(epInd).attributes('keepConstant');
            if strcmp(keepConstant,'area')
                area = ones(length(xVals),1).*initArea;
            else
                curOuterDiameter = rootData.curInnerDiameter+initThick*2;
                area = pi*((curOuterDiameter./2).^2-(rootData.curInnerDiameter./2).^2);
            end;
            yvals = yvals./area;
            errs = errs./area;
            
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['stimInterval_charge/area (' yField.units '/sq. micron)']);
        end
        
        function plot_innerDiameterVsstimInterval_chargeNORM_perArea(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.stimInterval_charge;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            
            %Find annulus area(s)
            epInd = node.get(2).epochID;
            epInd = epInd(1);
            initArea = cellData.epochs(epInd).attributes('initArea');
            initThick = cellData.epochs(epInd).attributes('initThick');
            keepConstant = cellData.epochs(epInd).attributes('keepConstant');
            if strcmp(keepConstant,'area')
                area = ones(length(xVals),1).*initArea;
            else
                curOuterDiameter = rootData.curInnerDiameter+initThick*2;
                area = pi*((curOuterDiameter./2).^2-(rootData.curInnerDiameter./2).^2);
            end;
            yvals = yvals./area;
            errs = errs./area;
            
            [M, Mind] = max(abs(yvals));
            if yvals(Mind) < 0
                yvals = -yvals./M;
            else
                yvals = yvals./M;
            end;
            errs = errs./M;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel('stimInterval_charge/area(norm)');
        end
        

        
        function plot_innerDiameterVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('inner diameter');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
        end
        
        function plot_innerDiameterVsspikeCount_stimInterval_baselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.spikeCount_stimInterval_baselineSubtracted;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSET_FRhalfMaxSusLatency(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSET_FRhalfMaxSusLatency;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('inner diameter');
            ylabel(['ONSET_FRhalfMaxSusLatency (' yField.units ')']);
         end
        
        function plot_innerDiameterVsONSET_FRhalfMaxSusLatency_inXlimits(node, cellData)
            xRangeMin = 180;
            xRangeMax = 700;
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSET_FRhalfMaxSusLatency;
            yvals = yField.value;
            xvalsNew = xvals((xvals>=xRangeMin)&(xvals<=xRangeMax));
            yvalsNew = yvals((xvals>=xRangeMin)&(xvals<=xRangeMax));
            plot(xvalsNew, yvalsNew, 'bx-');
            xlabel('inner diameter');
            ylabel(['ONSET_FRhalfMaxSusLatency (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSETspikesNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
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
            xlabel('inner diameter');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSETspikes_perAreaNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            
            %Find annulus area(s)
            epInd = node.get(2).epochID;
            epInd = epInd(1);
            initArea = cellData.epochs(epInd).attributes('initArea');
            initThick = cellData.epochs(epInd).attributes('initThick');
            keepConstant = cellData.epochs(epInd).attributes('keepConstant');
            if strcmp(keepConstant,'area')
                area = ones(length(xVals),1).*initArea;
            else
                curOuterDiameter = rootData.curInnerDiameter+initThick*2;
                area = pi*((curOuterDiameter./2).^2-(rootData.curInnerDiameter./2).^2);
            end;
            yvals = yvals./area;
            errs = errs./area;

            M = max(abs(yvals));
            yvals = yvals./M;
            errs = errs./M;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_innerDiameterVsONSETspikesNORM_inXlimits(node, cellData)
            xRangeMin = 180;
            xRangeMax = 700;
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
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
            xlabel('inner diameter');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_curInnerDiameterVsspikeCount_ONSET_after200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.spikeCount_ONSET_after200ms;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('curInnerDiameter');
            ylabel(['spikeCount_ONSET_after200ms (' yField.units ')']);
        end
        
        function plot_curInnerDiameterVsspikeCount_ONSET_after200ms_blSubt(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.spikeCount_ONSET_after200ms_baselineSubtracted;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('curInnerDiameter');
            ylabel(['spikeCount_ONSET_after200ms_baselineSubtracted (' yField.units ')']);
        end
        
        function plot_curInnerDiameterVsspikeCount_ONSET_after200ms_blSubtNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.spikeCount_ONSET_after200ms_baselineSubtracted;
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
            xlabel('curInnerDiameter');
            ylabel(['spikeCount_ONSET_after200ms_baselineSubtracted (' yField.units ')']);
        end
        
        function plot_innerDiameterVsspikeCount_stimInt_gblSubt(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
            yField = rootData.spikeCount_stimInterval_grndBlSubt;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('inner diameter');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
        end
        
         function plot_innerDiameterVsspikeCount_stimInt_gblSubtNORM(node, cellData)
            rootData = node.get(1);
            xvals = rootData.curInnerDiameter;
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
            xlabel('inner diameter');
            ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
        end
    end
    
end
