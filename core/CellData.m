classdef CellData < handle
    
    properties
        attributes %map for attributes from data file
        epochs
        epochGroups
        savedDataSets = containers.Map;
        savedFileName = '';
        savedFilters = containers.Map;
        tags = containers.Map;
        cellType = '';
        prefsMapName = '';
        somaSize = [];
        imageFile = ''; %cell image
        notes = ''; %unstructured text field for adding notes
        location = []; %[X, Y, whichEye] (X,Y in microns; whichEye is -1 for left eye and +1 for right eye)
    end
    
    
    methods
        function obj = CellData(fname)
            
            if nargin < 1
                return
            end

            %creates CellData object from raw data file
            [~, obj.savedFileName, ~] = fileparts(fname);
            info = hdf5info(fname,'ReadAttributes',false);
            info = info.GroupHierarchy(1);
            
            obj.attributes = mapAttributes(info.Groups(1), fname);
            %stuff here for epoch group attributes
            
            %Epoch attributes (protocol properties)
            %and data links
            %EpochDataGroups = info.Groups(1).Groups(2).Groups;
            %EpochDataGroups = info.Groups(1).Groups(1).Groups(1).Groups(2).Groups;
            
            %search through all EpochGroups (not just first one!!!)
            %GWS fixed on 6/6/14
            L = length(info.Groups);
            EpochDataGroups = [];
            for i=1:L
                EpochDataGroups = [EpochDataGroups info.Groups(i).Groups(2).Groups];
            end
            Nepochs = length(EpochDataGroups);
            %keyboard;
            obj.epochs = EpochData.empty(Nepochs, 0);
            %keyboard;
            %deal with epoch order here, not recorded in order
            %epochTimes = zeros(1,Nepochs);
            z=1;
            epochTimes = [];
            for i=1:Nepochs
                if length(EpochDataGroups(i).Groups) >= 3 %complete epoch
                    attributeMap = mapAttributes(EpochDataGroups(i), fname);
                    epochTimes(z) = attributeMap('startTimeDotNetDateTimeOffsetUTCTicks');
                    okEpochInd(z) = i;
                    z=z+1;
                end
            end
            
            Nepochs = length(epochTimes);
            if Nepochs>0
                obj.attributes('Nepochs') = Nepochs;
                
                [epochTimes_sorted, ind] = sort(epochTimes);
                epochTimes_sorted = epochTimes_sorted - epochTimes_sorted(1);
                epochTimes_sorted = double(epochTimes_sorted) / 1E7; %ticks to s
                
                z=1;
                for i=1:Nepochs
                    curEpoch = EpochData();
                    groupInd = okEpochInd(ind(i));
                    curEpoch.parentCell = obj;
                    curEpoch.loadParams(EpochDataGroups(groupInd).Groups(1), fname);
                    curEpoch.attributes('epochStartTime') = epochTimes_sorted(i);
                    curEpoch.attributes('epochNum') = i;
                    curEpoch.addDataLinks(EpochDataGroups(groupInd).Groups(2).Groups);
                    obj.epochs(i) = curEpoch;
                end
            end
        end
        
        function vals = getEpochVals(obj, paramName, epochInd)
            if nargin < 3
                epochInd = 1:obj.get('Nepochs');
            end
            L = length(epochInd);
            if isempty(L)
                vals = [];
                return;
            end
            vals = cell(1,L);
            allNumeric = true;
            for i=1:L
                v = obj.epochs(epochInd(i)).get(paramName);
                if isempty(v)
                    vals{i} = NaN;
                elseif strcmp(v, '<null>') || strcmp(v, 'null') %temp hack: null string?
                    vals{i} = nan;
                else
                    vals{i} = v;
                end
                if ~isnumeric(vals{i})
                    allNumeric = false;
                else
                    vals{i} = double(vals{i});
                end
            end
            if allNumeric
                vals = cell2mat(vals);
            end
            
        end
        
        function allKeys = getEpochKeysetUnion(obj, epochInd)
            if nargin < 2
                epochInd = 1:obj.get('Nepochs');
            end
            L = length(epochInd);
            if isempty(L)
                allKeys = [];
                return;
            end
            fullKeySet = [];
            for i=1:L
                fullKeySet = [fullKeySet obj.epochs(epochInd(i)).attributes.keys];
            end
            
            allKeys = unique(fullKeySet);
            [~,sortOrder] = sort(upper(allKeys)); % unique sorting puts capital letters before lowercase, so resort properly
            allKeys = allKeys(sortOrder);
        end
        
        function [params, vals] = getNonMatchingParamVals(obj, epochInd, excluded)
            if nargin < 3
                excluded = '';
            end
            excluded = {excluded, 'numberOfAverages', 'epochStartTime', 'identifier'};
            allKeys = obj.getEpochKeysetUnion(epochInd);
            L = length(allKeys);
            params = {};
            vals = {};
            z = 1;
            for i=1:L
                if ~strcmp(allKeys{i}, excluded)
                    curVals = getEpochVals(obj, allKeys{i}, epochInd);
                    curVals = curVals(~isnan_cell(curVals));
                    if iscell(curVals)
                        for j=1:length(curVals)
                            if isnumeric(curVals{j})
                                curVals{j} = num2str(curVals{j});
                            end
                        end
                    end
                    
                    uniqueVals = unique(curVals);
                    if length(uniqueVals) > 1
                        params{z} = allKeys{i};
                        vals{z} = uniqueVals;
                        z=z+1;
                    end
                end
            end
        end
        
        function [dataMean, xvals, dataStd, units] = getMeanData(obj, epochInd, streamName)
            if nargin < 3
                streamName = 'Amplifier_Ch1';
            end
            L = length(epochInd);
            dataPoints = length(obj.epochs(epochInd(1)).getData(streamName));
            M = zeros(L,dataPoints);
            for i=1:L
                [curData, curXvals, curUnits] = obj.epochs(epochInd(i)).getData(streamName);
                if i==1
                    xvals = curXvals;
                    units = curUnits;
                end
                M(i,:) = curData;
            end
            dataMean = mean(M,1);
            dataStd = std(M,1);
        end
        
        function plotMeanData(obj, epochInd, subtractBaseline, lowPass, streamName, ax)
            if nargin < 6
                ax = gca;
            end
            if nargin < 5
                streamName = 'Amplifier_Ch1';
            end
            if nargin < 4
                lowPass = [];
            end
            if nargin < 3
                subtractBaseline = true;
            end
            

            sampleEpoch = obj.epochs(epochInd(1));
            sampleRate = sampleEpoch.get('sampleRate');
            stimLen = sampleEpoch.get('stimTime')*1E-3; %s
            [dataMean, xvals, dataStd, units] = obj.getMeanData(epochInd, streamName);
            %could use dataStd to plot with error lines
            
            if ~isempty(dataMean)
                if ~isempty(lowPass)
                    dataMean = LowPassFilter(dataMean, lowPass, 1/sampleRate);
                end
                if subtractBaseline
                    baseline = mean(dataMean(xvals<0));
                    if isnan(baseline) %hack for missing baseline time
                        baseline = mean(dataMean(xvals<0.25)); %use 250 ms
                    end
                    dataMean = dataMean - baseline;
                end
                
                plot(ax, xvals, dataMean);
                if ~isempty(stimLen)
                    hold(ax, 'on');
                    startLine = line('Xdata', [0 0], 'Ydata', get(ax, 'ylim'), ...
                        'Color', 'k', 'LineStyle', '--');
                    endLine = line('Xdata', [stimLen stimLen], 'Ydata', get(ax, 'ylim'), ...
                        'Color', 'k', 'LineStyle', '--');
                    set(startLine, 'Parent', ax);
                    set(endLine, 'Parent', ax);
                end
                xlabel(ax, 'Time (s)');
                ylabel(ax, units);
                hold(ax, 'off');
            end
        end
        
        function [spCount, xvals] = getPSTH(obj, epochInd, binWidth, streamName)
            if nargin < 4
                streamName = 'Amplifier_Ch1';
            end
            if nargin < 3 || isempty(binWidth)
                binWidth = 10; %ms
            end
            sampleEpoch = obj.epochs(epochInd(1));
            dataPoints = length(sampleEpoch.getData(streamName));
            sampleRate = sampleEpoch.get('sampleRate');
            samplesPerMS = round(sampleRate/1E3);
            samplesPerBin = round(binWidth*samplesPerMS);
            bins = 0:samplesPerBin:dataPoints;
            
            %compute PSTH
            allSpikes = [];
            L = length(epochInd);
            for i=1:L
                allSpikes = [allSpikes, obj.epochs(epochInd(i)).getSpikes(streamName)];
            end
            spCount = histc(allSpikes,bins);
            if isempty(spCount)
                spCount = zeros(1,length(bins));
            end
            
            stimStart = sampleEpoch.get('preTime')*1E-3; %s
            if isnan(stimStart)
                stimStart = 0;
            end
            xvals = bins/sampleRate - stimStart;
            
            %convert to Hz
            spCount = spCount / L / (binWidth*1E-3);
            
        end
        
        function plotSpikeRaster(obj, epochInd, streamName)
            if nargin < 3
                streamName = 'Amplifier_Ch1';
            end
            
            %get spikes
            L = length(epochInd);
            spikeTimes = cell(L,1);
            for i=1:L
                [spikeTimes{i}, timeAxis_spikes] = obj.epochs(epochInd(i)).getSpikes(streamName);
            end
            ax = gca;
            cla(ax);
            hold(ax, 'on');
            
            % point display
%             for i=1:L
%                 h(i) = scatter(ax, timeAxis_spikes(spikeTimes{i}), i .* ones(1,length(spikeTimes{i})));
%                 set(h(i), 'Marker', '*', 'MarkerEdgeColor', 'k');
%             end
            
            % line display
            for i=1:L
                if isnan(spikeTimes{i})
                    warning('May need to detect spikes')
                    continue
                end
                spikes = timeAxis_spikes(spikeTimes{i});
                for st_i = 1:length(spikes)
                    x = spikes(st_i);
                    line([x, x], [i-0.4, i+0.4]);
                end
            end
            
            % use image display
%             img = [];
%             for i=1:L
%                 h(i) = scatter(ax, timeAxis_spikes(spikeTimes{i}), i .* ones(1,length(spikeTimes{i})));
%                 set(h(i), 'Marker', '*', 'MarkerEdgeColor', 'k');
%             end
%             imagesc(ax, img);
            
            set(ax, 'Ytick', 1:1:L);
            set(ax, 'Xlim', [timeAxis_spikes(1), timeAxis_spikes(end)]);
            set(ax, 'Ylim', [0, L+1]);
            %start and end lines
            sampleEpoch = obj.epochs(epochInd(1));
            stimLen = sampleEpoch.get('stimTime')*1E-3; %s
            if ~isempty(stimLen)
                startLine = line('Xdata', [0 0], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                endLine = line('Xdata', [stimLen stimLen], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                set(startLine, 'Parent', ax);
                set(endLine, 'Parent', ax);
            end
            xlabel(ax, 'Time (s)');
            ylabel(ax, 'Trials');
        end
        
        function plotPSTH(obj, epochInd, binWidth, streamName, ax)
            if nargin < 5
                ax = gca;
            end
            if nargin < 4
                streamName = 'Amplifier_Ch1';
            end
            if nargin < 3
                binWidth = 10;
            end

            if isempty(epochInd)
                error('No epochs supplied');
            end
            sampleEpoch = obj.epochs(epochInd(1));
            stimLen = sampleEpoch.get('stimTime')*1E-3; %s
            [spCount, xvals] = obj.getPSTH(epochInd, binWidth, streamName);
            
            plot(ax, xvals, spCount);
            if ~isempty(stimLen)
                hold(ax, 'on');
                startLine = line('Xdata', [0 0], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                endLine = line('Xdata', [stimLen stimLen], 'Ydata', get(ax, 'ylim'), ...
                    'Color', 'k', 'LineStyle', '--');
                set(startLine, 'Parent', ax);
                set(endLine, 'Parent', ax);
            end
            xlabel(ax, 'Time (s)');
            ylabel(ax, 'Spike rate (Hz)');
            %hold(ax, 'off');
        end
             
        function detectSpikes(obj, mode, threshold, epochInd, interactive, streamName)
            if nargin < 6
                streamName = 'Amplifier_Ch1';
            end
            if nargin < 5
                interactive = true;
            end
            if nargin < 4
                epochInd = 1:obj.get('Nepochs');
            end
            if nargin < 3
                threshold = 15;
            end
            if nargin < 2
                mode = 'Stdev';
            end
            L = length(epochInd);
            params.spikeDetectorMode = mode;
            params.spikeThreshold = threshold;
            if interactive
                SpikeDetectorGUI(obj, epochInd, params, streamName);
            else
                for i=1:L
                    obj.epochs(epochInd(i)).detectSpikes(params, streamName);
                end
            end
        end
        
        
        function dataSet = filterEpochs(obj, queryString, subSet)
            if nargin < 3
                subSet = 1:obj.get('Nepochs');
            end
            L = length(subSet);
            dataSet = [];
            if strcmp(queryString, '?') || isempty(queryString)
                dataSet = 1:L;
            else
                for i=1:L
                    M = obj.epochs(subSet(i)); %variable name of map in query string is M
                    %queryString
                    %i
                    %eval(queryString)
                    if eval(queryString)
                        dataSet = [dataSet subSet(i)];
                    end
                end
            end
        end
        
        function val = filterCell(obj, queryString)
            %returns true or false for this cell
            if strcmp(queryString, '?') || isempty(queryString)
                val = true;
            else
                M = obj; %variable name of map in query string is M
                val = eval(queryString);
            end
        end
        
        function val = get(obj, paramName) %checks attributes and tags
            if ~obj.attributes.isKey(paramName) && ~obj.tags.isKey(paramName)
                %disp(['Error: ' paramName ' not found']);
                val = nan;
            elseif obj.tags.isKey(paramName) %tags take precedence over attributes
                val = obj.tags(paramName);
            else
                val = obj.attributes(paramName);
            end
        end
        
        function display(obj)
            displayAttributeMap(obj.attributes)
        end
        
    end
end