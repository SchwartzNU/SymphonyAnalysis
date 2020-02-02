classdef SpikeDetectorGUI < handle
    properties
        fig
        handles
        mode
        threshold
        spikeTimes
        data
        cellData
        epochIndicesList
        curEpochListIndex
        sampleRate
        streamName
        epochsInDataSets
        spikeFilter
        filteredData
        noiseLevel
    end
    
    methods
        function obj = SpikeDetectorGUI(cellData, epochIndicesList, params, streamName)
            if nargin < 4
                obj.streamName = 'Amplifier_Ch1';
            else
                obj.streamName = streamName;
            end

            
            % to generate the spike filter, do:
%             spikeFilter = designfilt('bandpassiir', 'StopbandFrequency1', 200, 'PassbandFrequency1', 300, 'PassbandFrequency2', 3000, 'StopbandFrequency2', 3500, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', 10000);
%             save('SymphonyAnalysis/utilities/spikeFilter.mat', 'spikeFilter')

            sf = load('utilities/spikeFilter.mat');
            obj.spikeFilter = sf.spikeFilter;

            obj.cellData = cellData;
%             obj.epochIndicesList = epochIndicesList; % don't even use it if we're just overwriting it
            obj.mode = params.spikeDetectorMode;
            obj.threshold = params.spikeThreshold;
            obj.curEpochListIndex = 1;
            obj.initializeEpochsInDataSetsList();
            obj.epochIndicesList = sort(unique(obj.epochsInDataSets));
            if isempty(obj.epochIndicesList)
                error('No data set epochs found, may need curation');
            end
            
            obj.buildUI();
            
            obj.loadCurrentEpochResponse();
            obj.updateUI();
            
        end
        
        function buildUI(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['Spike Detector: Epoch ' num2str(obj.epochIndicesList(obj.curEpochListIndex))], ...
                'NumberTitle',  'off', ...
                'Menubar',      'none', ...                         
                'ToolBar',      'none',...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
%                 'Position', [0 0.4*bounds(4), 1000, 500], ...
            
            
            L_main = uix.VBox('Parent', obj.fig);
            
            L_info = uix.HBox('Parent', L_main, ...
                'Spacing', 2);
            
            obj.handles.autoSaveCheckbox = uicontrol('Parent', L_info, ...
                'Style', 'checkbox', ...
                'String', 'Autosave', ...
                'Value', true, ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.saveNowButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Save & Sync', ...
                'Callback', @(uiobj, evt)obj.autoSave(true), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));            
            
            uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Spike detector mode');
            obj.handles.detectorModeMenu = uicontrol('Parent', L_info, ...
                'Style', 'popupmenu', ...
                'String', {'Standard deviations above noise', 'Simple threshold', 'advanced'});
            switch obj.mode
                case 'Stdev'
                    set(obj.handles.detectorModeMenu, 'value', 1);
                case 'threshold'
                    set(obj.handles.detectorModeMenu, 'value', 2);
                case 'advanced'
                    set(obj.handles.detectorModeMenu, 'value', 3);
            end
            uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Threshold:');
            obj.handles.thresholdEdit = uicontrol('Parent', L_info, ...
                'Style', 'edit', ...
                'String', num2str(obj.threshold), ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.reDetectButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', 'FontWeight', 'bold', 'FontSize', 14, ...
                'String', 'Detect spikes', ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.clearSpikesButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Clear spikes', ...
                'Callback', @(uiobj, evt)obj.clearSpikes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.clickThresholdButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Click Threshold', ...
                'Callback', @(uiobj, evt)obj.clickThreshold(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));            
            obj.handles.selectValidSpikesButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Select valid region', ...
                'Callback', @(uiobj, evt)obj.selectValidSpikes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
            
            L_plotBox = uix.VBoxFlex('Parent', L_main);
            obj.handles.primaryAxes = axes('Parent', L_plotBox, ...
                'ButtonDownFcn', @axisZoomCallback);
            obj.handles.secondaryAxes = axes('Parent', L_plotBox);
            L_plotBox.Heights = [-1, -1];
            
            bottomButtonBlock = uix.HBox('Parent', L_main);
            obj.handles.applyToAllButton = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to all', ...
                'Callback', @(uiobj, evt)obj.updateAllSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.applyToFutureButton = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to this & future', ...
                'Callback', @(uiobj, evt)obj.updateFutureSpikeTimes(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.skipBackward10 = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Back 10', ...
                'Callback', @(uiobj, evt)obj.skipBackward10(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            obj.handles.skipForward10 = uicontrol('Parent', bottomButtonBlock, ...
                'Style', 'pushbutton', ...
                'String', 'Forward 10', ...
                'Callback', @(uiobj, evt)obj.skipForward10(), ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
            set(L_main, 'Heights', [50, -1, 50]);
            set(L_info, 'Widths', [-.8, -.8, -.8, -1.5, -.8, -.6, -2, -1, -1, -1]);
        end
        
        function detectSpikes(obj, index)
            epoch = obj.cellData.epochs(obj.epochIndicesList(index));
            
            if isSpikeEpoch(epoch, obj.streamName)
                % get response for this epoch
                response = epoch.getData(obj.streamName);
                response = response - mean(response);
                response = response';
               
                % get detection config
                ind = get(obj.handles.detectorModeMenu, 'value');
                s = get(obj.handles.detectorModeMenu, 'String');
                obj.mode = s{ind};
                obj.threshold = str2double(get(obj.handles.thresholdEdit, 'String'));
                
                if strcmp(obj.mode, 'Simple threshold')
                    spikeIndices = getThresCross(response, obj.threshold, sign(obj.threshold));
                    
                    % refine spike locations to tips
                    if obj.threshold < 0
                        for si = 1:length(spikeIndices)
                            sp = spikeIndices(si);
                            if sp < 100 || sp > length(response) - 100
                                continue
                            end
                            while response(sp) > response(sp+1)
                                sp = sp+1;
                            end
                            while response(sp) > response(sp-1)
                                sp = sp-1;
                            end
                            spikeIndices(si) = sp;
                        end
                    else
                        for si = 1:length(spikeIndices)
                            sp = spikeIndices(si);
                            if sp < 100 || sp > length(response) - 100
                                continue
                            end                            
                            while response(sp) < response(sp+1)
                                sp = sp+1;
                            end
                            while response(sp) < response(sp-1)
                                sp = sp-1;
                            end
                            spikeIndices(si) = sp;
                        end
                    end
                    
                elseif strcmp(obj.mode, 'advanced')
                    [fresponse, noise] = obj.filterResponse(response);
                    spikeIndices = getThresCross(fresponse, noise * obj.threshold, sign(obj.threshold));
                    
                    % refine spike locations to tips
                    if obj.threshold < 0
                        for si = 1:length(spikeIndices)
                            sp = spikeIndices(si);
                            if sp < 100 || sp > length(response) - 100
                                continue
                            end
                            while response(sp) > response(sp+1)
                                sp = sp+1;
                            end
                            while response(sp) > response(sp-1)
                                sp = sp-1;
                            end
                            spikeIndices(si) = sp;
                        end
                    else
                        for si = 1:length(spikeIndices)
                            sp = spikeIndices(si);
                            if sp < 100 || sp > length(response) - 100
                                continue
                            end                             
                            while response(sp) < response(sp+1)
                                sp = sp+1;
                            end
                            while response(sp) < response(sp-1)
                                sp = sp-1;
                            end
                            spikeIndices(si) = sp;
                        end
                    end
                    
                elseif strcmp(epoch.get('ampMode'), 'Cell attached')
                    spikeResults = SpikeDetector_simple(response, 1./obj.sampleRate, obj.threshold);
                    spikeIndices = spikeResults.sp;
                else %different spike dtector for Iclamp data
                    spikeResults = SpikeDetector_simple_Iclamp(response, 1./obj.sampleRate, obj.threshold);
                    spikeIndices = spikeResults.sp;
                end
                
                %remove double-counted spikes
                if length(spikeIndices) >= 2
                    ISItest = diff(spikeIndices);
                    spikeIndices = spikeIndices([(ISItest > (0.001 * obj.sampleRate)) true]);
                end

            else
                spikeIndices = [];
            end
            
            if index == obj.curEpochListIndex
                obj.spikeTimes = spikeIndices; % for plotting now
            end

            % save spikes in the epoch
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end

            epoch.attributes(channel) = spikeIndices;

        end
        
        
        function updateSpikeTimes(obj)
            obj.detectSpikes(obj.curEpochListIndex);
            
            obj.autoSave();         
            
            obj.updateUI();
        end
        
        function updateAllSpikeTimes(obj)           
            for index = 1:length(obj.epochIndicesList)
                set(obj.fig, 'Name', sprintf('Detecting spikes: epoch %g', obj.epochIndicesList(index)));
                drawnow;
                obj.detectSpikes(index);
            end
            
            obj.autoSave();
            
            obj.updateUI();
        end

        function updateFutureSpikeTimes(obj)
            for index=1:length(obj.epochIndicesList)
                
                if index < obj.curEpochListIndex
                    continue
                end
                set(obj.fig, 'Name', sprintf('Detecting spikes: epoch %g', obj.epochIndicesList(index)));
                drawnow;
                obj.detectSpikes(index);
            end
            
            obj.autoSave();
            
            obj.updateUI();
        end
        
        function autoSave(obj, force)
            if nargin == 1
                force = false;
            end
            if force || obj.handles.autoSaveCheckbox.Value
                set(obj.fig, 'Name', 'Saving');
                drawnow;
                saveAndSyncCellData(obj.cellData);
                set(obj.fig, 'Name', 'Saved');
                drawnow;
            end
        end
        
        function loadCurrentEpochResponse(obj)
            epoch = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex));
            obj.sampleRate = epoch.get('sampleRate');
            obj.data = epoch.getData(obj.streamName);
            obj.data = obj.data - mean(obj.data);
            obj.data = obj.data';
            [obj.filteredData, obj.noiseLevel] = obj.filterResponse(obj.data);
            
            %load spike times if they are present
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end
            
            loadedSpikes = epoch.get(channel);
            needToGetSpikes = isnan(loadedSpikes) & length(loadedSpikes) == 1;
            if needToGetSpikes
                obj.updateSpikeTimes();
            else
                obj.spikeTimes = loadedSpikes;
            end
            
            obj.updateUI();
        end
        
        function clearSpikes(obj)
            obj.spikeTimes = [];

            epoch = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex));
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end
            
            epoch.attributes(channel) = obj.spikeTimes;
        
            obj.autoSave();
            
            obj.updateUI();
            
        end
        
        function clickThreshold(obj)
            [~,y] = ginput(1);
            ax = gca();
            if(ax == obj.handles.primaryAxes)
                obj.mode = 'Simple threshold';
                set(obj.handles.detectorModeMenu, 'Value', 2);
            elseif(ax == obj.handles.secondaryAxes)
                obj.mode = 'advanced';
                set(obj.handles.detectorModeMenu, 'Value', 3);
                y = y;% / obj.noiseLevel;
            else
                return
            end
                
            obj.threshold = y;
%             obj.mode = 'Simple threshold';
            set(obj.handles.thresholdEdit, 'String', num2str(obj.threshold, 2));
%             set(obj.handles.detectorModeMenu, 'Value', 2);
            obj.updateSpikeTimes()
        end
        
        function selectValidSpikes(obj)
            selection = getrect(obj.handles.primaryAxes);
            times = obj.spikeTimes / obj.sampleRate;
            amps = obj.data(obj.spikeTimes);

            selectX = times > selection(1) & times < selection(1) + selection(3);
            selectY = amps > selection(2) & amps < selection(2) + selection(4);
            
            obj.spikeTimes(~(selectX & selectY)) = [];
            
            epoch = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex));
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end
            
            epoch.attributes(channel) = obj.spikeTimes;
            
            obj.autoSave();
            
            obj.updateUI();
        end
        

        
        function skipBackward10(obj)
            obj.curEpochListIndex = max(obj.curEpochListIndex-10, 1);
            obj.loadCurrentEpochResponse();
        end
        function skipForward10(obj)
            obj.curEpochListIndex = min(obj.curEpochListIndex+10, length(obj.epochIndicesList));
            obj.loadCurrentEpochResponse();
        end
        
        function initializeEpochsInDataSetsList(obj)
           k = obj.cellData.savedDataSets.keys;
           for i=1:length(k)
               obj.epochsInDataSets = [obj.epochsInDataSets obj.cellData.savedDataSets(k{i})];
           end
        end
        
        function updateUI(obj)
            if isempty(obj.data)
                disp('empty response')
                cla(obj.handles.primaryAxes)
                drawnow
                return
            end
            t = (0:length(obj.data)-1) / obj.sampleRate;
            plot(obj.handles.primaryAxes, t, obj.data, 'k');
            hold(obj.handles.primaryAxes, 'on');
            plot(obj.handles.primaryAxes, t(obj.spikeTimes), obj.data(obj.spikeTimes), 'ro', 'MarkerSize', 10, 'linewidth', 2);
            if strcmp(obj.mode, 'Simple threshold')
                xax = xlim(obj.handles.primaryAxes);
                line(xax, [1,1]*obj.threshold, 'LineStyle', '-', 'Color', 'g', 'Parent', obj.handles.primaryAxes);
            end
            title(obj.handles.primaryAxes, 'Raw data');
            hold(obj.handles.primaryAxes, 'off');
            xlim(obj.handles.primaryAxes, [min(t), max(t)+eps]);
            
            % advanced filtered plot
            plot(obj.handles.secondaryAxes, t, obj.filteredData / obj.noiseLevel, 'k');
            hold(obj.handles.secondaryAxes, 'on');
            plot(obj.handles.secondaryAxes, t(obj.spikeTimes), obj.filteredData(obj.spikeTimes) / obj.noiseLevel, 'ro', 'MarkerSize', 10, 'linewidth', 2);
            xax = xlim(obj.handles.secondaryAxes);
            
            line(xax, 1*[1,1], 'LineStyle', '--', 'Color', 'r', 'Parent', obj.handles.secondaryAxes);
            line(xax, -1*[1,1], 'LineStyle', '--', 'Color', 'r', 'Parent', obj.handles.secondaryAxes);
            if strcmp(obj.mode, 'advanced')
                line(xax, obj.threshold*[1,1], 'LineStyle', '-', 'Color', 'g', 'Parent', obj.handles.secondaryAxes);
            end
%             legend(obj.handles.secondaryAxes, 'test', 'Location', 'Best')
            hold(obj.handles.secondaryAxes, 'off');
            title(obj.handles.secondaryAxes, 'Filtered version for advanced detector');
            xlim(obj.handles.secondaryAxes, [min(t), max(t)]);
            
            displayName = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex)).get('displayName');
            set(obj.fig, 'Name',['Spike Detector: Epoch ' num2str(obj.epochIndicesList(obj.curEpochListIndex)) ' (' displayName '): ' num2str(length(obj.spikeTimes)) ' spikes, ' obj.streamName]);
            drawnow
        end
        
        function [fdata, noise] = filterResponse(obj, fdata)
            if isempty(fdata)
                noise = [];
                return
            end
            fdata = [fdata(1) + zeros(1,2000), fdata, fdata(end) + zeros(1,2000)];
            fdata = filtfilt(obj.spikeFilter, fdata);
            fdata = fdata(2001:(end-2000));
            noise = median(abs(fdata) / 0.6745);
        end
        
        
        function keyHandler(obj, evt)
            switch evt.Key
                case 'leftarrow'
                    obj.curEpochListIndex = max(obj.curEpochListIndex-1, 1);
                    obj.loadCurrentEpochResponse();
                case 'rightarrow'
                    obj.curEpochListIndex = min(obj.curEpochListIndex+1, length(obj.epochIndicesList));
                    obj.loadCurrentEpochResponse();
                case 'escape'
                    delete(obj.fig);
                otherwise
                    %disp(evt.Key);
            end
        end
        
    end
    
end