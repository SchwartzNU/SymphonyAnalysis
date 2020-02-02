classdef MultiPulseAnalysis < AnalysisTree
    properties
        %these are kind of obsolete. Not really used in this analysis.
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = MultiPulseAnalysis(cellData, dataSetName, params)
            %choose with amplifier
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
            
            %name for the analysis based on cellName, dataset and analysis
            %type
            nameStr = [cellData.savedFileName ': ' dataSetName ': MultiPulseAnalysis'];            
            
            %obj saves the analysis tree
            obj = obj.setName(nameStr); %put in the name
            dataSet = cellData.savedDataSets(dataSetName); %get the data set 
            obj = obj.copyAnalysisParams(params); %copies analysis parameters into the object. In this case, there are no interesting ones

            %take some parameters from the first epoch and copy them into
            %the analysis tree
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam, 'intensity', 'stepByStim', 'pulse1Curr', 'pulse2Curr', ...
                'wholeCellRecordingMode_Ch1', 'offsetX', 'offsetY'});

            if strcmp(obj.Node{1}.stepByStim, 'Stim 1') %if stepping by stim!
                obj = obj.buildCellTree(1, cellData, dataSet, {'pulse1Curr'}); %split by stim 1 pulse amplitude
            elseif strcmp(obj.Node{1}.stepByStim, 'Stim 2') %stepping by stim 2
                obj = obj.buildCellTree(1, cellData, dataSet, {'pulse2Curr'}); %split by stim 2 pulse amplitude
            else
                warning('Split param for different timings not implemented yet')
            end
            
        end
        
        function obj = doAnalysis(obj, cellData)
           rootData = obj.get(1); %root node of analysis tree
           leafIDs = obj.findleaves(); %indices of leaf nodes
           
            L = length(leafIDs);

            % Greg wrote twoooo?
            % Plotters were written off of Sophia's getEpochResponses:
            % getEpochResponses_actionCurrents_WC
            for i=1:L %loop over leaves. Stim params are the same within epochs in each leaf.               
                curNode = obj.get(leafIDs(i)); %get current leaf node
                
                if strcmp(obj.Node{1}.wholeCellRecordingMode_Ch1, 'Vclamp')
                    continue
                    %run your epoch analyses on this leaf node
                    outputStruct = getEpochResponses_WC_ActionCurrents(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName); 
                    %this helper function computes, means, medians, std, sterr, outliers, for each parameter that is a vector over epochs  
                    outputStruct = getEpochResponseStats(outputStruct);
                    %merge the results of these analyses into the leaf node
                    curNode = mergeIntoNode(curNode, outputStruct);
                elseif strcmp(obj.Node{1}.wholeCellRecordingMode_Ch1, 'Iclamp')
                    outputStruct = getEpochResponses_WC_MP_IC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName); 
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                %put the updated leaf node back into the analysis tree
                obj = obj.set(leafIDs(i), curNode);
            end

            
            %For each node, take the splitValue (in this case pulse1
            %amplitide) and collect it as a vector one level up under the
            %name 'pulseAmplitude'. YOu can use the percolateUp function
            %with as many argument pairs like this as you want to collect data
            %from lower levels of the tree up into vectors or cell arrays
            %in higher levels. The first argument in the pair is the
            %parameter you want to collect, the second is whatever name you
            %want to give it.
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'pulseAmplitude');
            
            %collect lists of parameters by their type, either ones that
            %have a value for each epoch or those that have a single value
            %across epochs, like the peak of the average trace
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            
            %percolate up all the computed parameters. This means you get a
            %correctly named vector of the result of each parameter at the
            %level above the leaves
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            %set variables called byEpochParamList, collectedParamList and
            %stimParameterList in the node above the leaves. These are used
            %by the automatic plotting function in TreeBrowserGUI. 
            %stimParameterList should include anything you want to check
            %out as the X axis in your plots. 
            %The other param lists are things that you want to see as the Y
            %axis.
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'pulseAmplitude', ...
                'Vm_preTime', 'Vm_stim1Time', 'Vm_stim2Time'};
            
            %copy your changes back into the analysisTree
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
        
        function plot_currPulsevStim1SpikeCount(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = rootData.pulseAmplitude;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                yvals(i) = chData.s1_spikeCount.mean;
                errs(i) = chData.s1_spikeCount.SEM;              
            end
            errorbar(xvals, yvals, errs);
            xlabel(['Step By Stim:' rootData.stepByStim])
            ylabel('Spike Count')
        end
        
        function plot_currPulsevStim2SpikeCount(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = ones(1, L)*NaN;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                if strcmp(rootData.stepByStim, 'Stim 1')
                    xvals(i) = chData.s1_steps.value;
                elseif strcmp(rootData.stepByStim, 'Stim 2')
                    xvals(i) = chData.s2_steps.value;
                end
                yvals(i) = chData.s2_spikeCount.mean;
                errs(i) = chData.s2_spikeCount.SEM;              
            end
            errorbar(xvals, yvals, errs);
            xlabel(['Step By Stim:' rootData.stepByStim])
            ylabel('Spike Count')
        end
        
        function plot_Vm_stim1TimeVss1_spikeCount(node, cellData)
            rootData = node.get(1);
            xvals = rootData.Vm_stim1Time.value;
            yField = rootData.s1_spikeCount;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('Vm_stim1Time');
            ylabel(['s1_spikeCount (' yField.units ')']);
        end
        
        function plot_Vm_stim2TimeVss2_spikeCount(node, cellData)
            rootData = node.get(1);
            xvals = rootData.Vm_stim2Time.value;
            yField = rootData.s2_spikeCount;
            if strcmp(yField.units, 's')
            yvals = yField.median_c;
            else
            yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('Vm_stim2Time');
            ylabel(['s2_spikeCount (' yField.units ')']);
        end
        
        function plot_StepHoldVsSpikeRaster(node, cellData)
            % copied from CellData class 011720 SRW   
            if nargin < 3
                streamName = 'Amplifier_Ch1';
            end 
            
            rootData = node.get(1);
            ds = strsplit(rootData.name, ': ');
            ds = ds{2};
            epochInd = cellData.savedDataSets(ds);
            sampleEpoch = cellData.epochs(epochInd(1));
            
            %get spikes
            L = length(epochInd);
            spikeTimes = cell(L,1);
            steps = nan(L, 1);
            for i=1:L
                [spikeTimes{i}, timeAxis_spikes] = cellData.epochs(epochInd(i)).getSpikes(streamName);
                if strcmp(sampleEpoch.get('stepByStim'), 'Stim 1')
                    steps(i) = cellData.epochs(epochInd(i)).get('pulse1Curr');
                else
                    steps(i) = cellData.epochs(epochInd(i)).get('pulse2Curr');
                end
            end
            ax = gca;
            cla(ax);
            hold(ax, 'on');
            
            % sort based on step
            [sortedSteps, sortedI] = sort(steps);
            epochOrder = [1:L];
            sortedEpochOrder = epochOrder(sortedI);
            
            % line display
            for i=1:L
                ind = sortedEpochOrder(i);
                if isnan(spikeTimes{ind})
                    warning('May need to detect spikes')
                    continue
                end
                spikes = timeAxis_spikes(spikeTimes{ind});
                for st_i = 1:length(spikes)
                    x = spikes(st_i);
                    line([x, x], [i-0.4, i+0.4]);
                end
            end
            
            set(ax, 'Ytick', 1:1:L);
            yticklabels(ax, compose('%d', sortedSteps))
            set(ax, 'Xlim', [timeAxis_spikes(1), timeAxis_spikes(end)]);
            set(ax, 'Ylim', [0, L+1]);
            %start and end lines
            stimLen = (sampleEpoch.get('stim1Time') + sampleEpoch.get('stim2Time'))*1E-3; %s
            if ~isempty(stimLen)
                startLine = line('Xdata', [0 0], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                endLine = line('Xdata', [stimLen stimLen], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                set(startLine, 'Parent', ax);
                set(endLine, 'Parent', ax);
            end
            xlabel(ax, 'Time (s)');
            ylabel(ax, 'Steps (pA)');
        end
        
        function plot_VmVsSpikeRaster(node, cellData)
            % copied from CellData class 011720 SRW   
            if nargin < 3
                streamName = 'Amplifier_Ch1';
            end 
            
            rootData = node.get(1);
            ds = strsplit(rootData.name, ': ');
            ds = ds{2};
            epochInd = cellData.savedDataSets(ds);
            sampleEpoch = cellData.epochs(epochInd(1));
            preT = sampleEpoch.get('preTime'); sampR = sampleEpoch.get('sampleRate');
            if strcmp(sampleEpoch.get('stepByStim'), 'Stim 1')
                stimT = sampleEpoch.get('stim1Time');
            else
                stimT = sampleEpoch.get('stim2Time');
            end
            
            % get use input on min number of spikes
            minNumSpikes = input('Min number of spikes to accept: ');
            
            %get spikes and appropriate info for sorting
            L = length(epochInd);
            spikeTimes = cell(L,1);
            steps = nan(L, 1);
            stimSpikes = nan(L, 1);
            holds = nan(L, 1);
            for i=1:L
                [ST, timeAxis_spikes] = cellData.epochs(epochInd(i)).getSpikes(streamName);
                spikeTimes{i} = ST;
                if strcmp(sampleEpoch.get('stepByStim'), 'Stim 1')
                    steps(i) = cellData.epochs(epochInd(i)).get('pulse1Curr');
                else
                    steps(i) = cellData.epochs(epochInd(i)).get('pulse2Curr');
                end
                holds(i) = cellData.epochs(epochInd(i)).get('ampHoldSignal');
                stimSpikes(i) = sum((ST > preT*sampR/1000) & (ST < (preT + stimT)*sampR/1000)) > minNumSpikes-1;
            end
            stimSpikes(stimSpikes == 0) = nan;
            
            ax = gca;
            cla(ax);
            hold(ax, 'on');
            
            % sort based on step
            stepInds = minStepPerVm(holds, steps, stimSpikes);
            holds = holds(stepInds);
            steps = steps(stepInds);
            spikeTimes = spikeTimes(stepInds, :);
            L2 = length(holds);
            [sortedHolds, sortedI] = sort(holds);
            epochOrder = [1:L];
            sortedEpochOrder = epochOrder(sortedI);
            sortedSteps = steps(sortedI);
            
            % line display
            for i=1:L2
                ind = sortedEpochOrder(i);
                if isnan(spikeTimes{ind})
                    warning('May need to detect spikes')
                    continue
                end
                spikes = timeAxis_spikes(spikeTimes{ind});
                for st_i = 1:length(spikes)
                    x = spikes(st_i);
                    line([x, x], [i-0.4, i+0.4]);
                end
            end
            
            tickInds = 1:floor(sampleEpoch.get('numberOfCycles')/2):L2;
            set(ax, 'Ytick', tickInds);
            yticklabels(ax, compose('%d, %d', sortedHolds(tickInds), sortedSteps(tickInds)))
            set(ax, 'Xlim', [timeAxis_spikes(1), timeAxis_spikes(end)]);
            set(ax, 'Ylim', [0, L2+1]);
            %start and end lines
            stimLen = (stimT)*1E-3; %s
            if ~isempty(stimLen)
                startLine = line('Xdata', [0 0], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                endLine = line('Xdata', [stimLen stimLen], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                set(startLine, 'Parent', ax);
                set(endLine, 'Parent', ax);
            end
            xlabel(ax, 'Time (s)');
            ylabel(ax, 'Hold (pA), Step (pA)');
        end
        
    end
end

