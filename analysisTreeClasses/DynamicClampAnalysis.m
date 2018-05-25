classdef DynamicClampAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 1000;
    end
    
    methods
        function obj = DynamicClampAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': DynamicClampAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {params.ampModeParam, 'ampHoldSignal', 'gExcMultiplier', 'gInhMultiplier'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'conductanceMatrixRowIndex'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);  %for grandBaseline subt. Adam 2/17/13
            
            
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
                'splitValue', 'conductanceMatrixRowIndex');
            
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
            
            
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'conductanceMatrixRowIndex'};
            obj = obj.set(1, rootData);
            % % %
            
        end
        
    end
    
    
    
    
    methods(Static)
             
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
        
        function plotMeanTraces(node, cellData)
            rootData = node.get(1);
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = axes;
            for i=1:L
                hold(ax, 'on');
                epochInd = node.get(chInd(i)).epochID;
                cellData.plotMeanData(epochInd, true, [], rootData.deviceName, ax);
            end
            hold(ax, 'off');
        end
        
%         function plot_conductanceIndexVspikeCount_stimInter_baseSubtracted(node, cellData)
%             rootData = node.get(1);
%             xvals = rootData.conductanceMatrixRowIndex;
%             yField = rootData.spikeCount_stimInterval_baselineSubtracted;
%             if strcmp(yField.units, 's')
%                 yvals = yField.median_c;
%             else
%                 yvals = yField.mean_c;
%             end
%             errs = yField.SEM;
%             errorbar(xvals, yvals, errs);
%             xlabel('rowIndex');
%             ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField.units ')']);
%         end
                 
    end
    
end
