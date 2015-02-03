classdef SpotsMultiSizeAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
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
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'curSpotSize'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            
            for i=1:L %for each leaf node
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
                'splitValue', 'spotSize');
            
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
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'spotSize'};
            obj = obj.set(1, rootData);
            % % %
            
        end
        
    end
    
    
    
    
    methods(Static)
        
        %         function plotDataSpikeCount(node, cellData)
        %             rootData = node.get(1);
        %             %errorbar(rootData.spotSize, rootData.respMean, rootData.respSEM);
        %             plot(rootData.spotSize, [rootData.meanONenhancedSpikes; rootData.meanOFFenhancedSpikes])
        %             xlabel('Spot size (microns)');
        %             if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
        %                 ylabel('ON spikes, OFF spikes');
        %             else
        %                 ylabel('Charge (pC)');
        %             end
        %         end
        %
        %         function plotDataLatencies(node, cellData)
        %             rootData = node.get(1);
        %             %errorbar(rootData.spotSize, rootData.respMean, rootData.respSEM);
        %             plot(rootData.spotSize, [rootData.medianONlatency; rootData.medianOFFlatency])
        %             xlabel('Spot size (microns)');
        %             if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
        %                 ylabel('ON spikes, OFF spikes');
        %             else
        %                 ylabel('Charge (pC)');
        %             end
        %         end
%         
%         function plotMeanTrace(node, cellData)
%             rootData = node.get(1);
%             epochInd = node.get(2).epochID;
%             if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
%                 cellData.plotPSTH(epochInd, 10, rootData.deviceName);
%                 %                 hold on
%                 %                 firingStart = node.get(2).meanONlatency;
%                 %                 firingEnd = firingStart + node.get(2).meanONenhancedDuration;
%                 %                 plot([firingStart firingEnd], [0 0]);
%                 %                 hold off
%             else
%                 cellData.plotMeanData(epochInd, true, [], rootData.deviceName);
%             end
%             %title(['ON latency: ',num2str(node.get(2).meanONlatency),' ste: ',num2str(node.get(2).steONlatency)]);
%         end
        
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
        
    end
    
end
