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
        dataFilter
    end
    
    methods
        function obj = SpikeDetectorGUI(cellData, epochIndicesList, params, streamName)
            if nargin < 4
                obj.streamName = 'Amplifier_Ch1';
            else
                obj.streamName = streamName;
            end

%             if obj.sampleRate ~= 10000
%                 sr = obj.sampleRate;
%             else
%                 sr = 10000;
%             end
%             obj.dataFilter = designfilt('bandpassiir', 'StopbandFrequency1', 100, 'PassbandFrequency1', 200, 'PassbandFrequency2', 3000, 'StopbandFrequency2', 3500, 'StopbandAttenuation1', 60, 'PassbandRipple', 1, 'StopbandAttenuation2', 60, 'SampleRate', sr);          
            
            obj.cellData = cellData;
%             obj.epochIndicesList = epochIndicesList; % don't even use it if we're just overwriting it
            obj.mode = params.spikeDetectorMode;
            obj.threshold = params.spikeThreshold;            
            obj.curEpochListIndex = 1;
            obj.initializeEpochsInDataSetsList();
            obj.epochIndicesList = sort(unique(obj.epochsInDataSets));
            
            obj.buildUI();
            
            obj.loadCurrentEpochResponse();
            obj.updateSpikeTimes();
            obj.updateUI();
            
        end
        
        function buildUI(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['Spike Detector: Epoch ' num2str(obj.epochIndicesList(obj.curEpochListIndex))], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ...
                'Position', [0 0.4*bounds(4), 1000, 500], ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
            L_main = uiextras.VBox('Parent', obj.fig);
            
            L_info = uiextras.HBox('Parent', L_main, ...
                'Spacing', 2);
            
            obj.handles.autoSaveCheckbox = uicontrol('Parent', L_info, ...
                'Style', 'checkbox', ...
                'String', 'Autosave', ...
                'Value', true);
            obj.handles.saveNowButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Save & Sync', ...
                'Callback', @(uiobj, evt)obj.saveNow());            
            
            uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Spike detector mode');
            obj.handles.detectorModeMenu = uicontrol('Parent', L_info, ...
                'Style', 'popupmenu', ...
                'String', {'Standard deviations above noise', 'Simple threshold'});
            if strcmp(obj.mode, 'Stdev')
                set(obj.handles.detectorModeMenu, 'value', 1);
            else
                set(obj.handles.detectorModeMenu, 'value', 2);
            end
            uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Threshold:');
            obj.handles.thresholdEdit = uicontrol('Parent', L_info, ...
                'Style', 'edit', ...
                'String', num2str(obj.threshold), ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes());
            obj.handles.reDetectButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Re-detect spikes', ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes());
            obj.handles.clearSpikesButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Clear spikes', ...
                'Callback', @(uiobj, evt)obj.clearSpikes());
            obj.handles.selectValidSpikesButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Select region', ...
                'Callback', @(uiobj, evt)obj.selectValidSpikes());
            obj.handles.applyToAllButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to all epochs', ...
                'Callback', @(uiobj, evt)obj.updateAllSpikeTimes());
            obj.handles.applyToFutureButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to this & future epochs', ...
                'Callback', @(uiobj, evt)obj.updateFutureSpikeTimes());
            obj.handles.skipBackward10 = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Back 10', ...
                'Callback', @(uiobj, evt)obj.skipBackward10());
            obj.handles.skipForward10 = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Forward 10', ...
                'Callback', @(uiobj, evt)obj.skipForward10());
            set(L_info, 'Sizes', [-.7, -1, -1, -1.5, -1, -.6, -1, -1, -1, -1, -1, -.5, -.5]);
            obj.handles.ax = axes('Parent', L_main, ...
                'ButtonDownFcn', @axisZoomCallback);
            set(L_main, 'Sizes', [40, -1]);
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
                    st = getThresCross(response, obj.threshold,sign(obj.threshold));
%                 elseif strcmp(obj.mode, 'advanced')
%                     disp('not quite yet')
                elseif strcmp(epoch.get('ampMode'), 'Cell attached')
                    spikeResults = SpikeDetector_simple(response, 1./obj.sampleRate, obj.threshold);
                    st = spikeResults.sp;
                else %different spike dtector for Iclamp data
                    spikeResults = SpikeDetector_simple_Iclamp(response, 1./obj.sampleRate, obj.threshold);
                    st = spikeResults.sp;
                end
                
                %remove double-counted spikes
                if  length(st) >= 2
                    ISItest = diff(st);
                    st = st([(ISItest > 0.001) true]);
                end

            else
                st = [];
            end
            
            if index == obj.curEpochListIndex
                obj.spikeTimes = st; % for plotting now
            end

            % save spikes in the epoch
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                channel = 'spikes_ch1';
            else
                channel = 'spikes_ch2';
            end

            epoch.attributes(channel) = st;

        end
        
        
        function updateSpikeTimes(obj)
            obj.detectSpikes(obj.curEpochListIndex);
            
            if obj.handles.autoSaveCheckbox.Value
                saveAndSyncCellData(obj.cellData);
            end            
            
            obj.updateUI();
        end
        
        function updateAllSpikeTimes(obj)           
            for index = obj.epochIndicesList
%                 set(obj.fig, 'Name', sprintf('Detecting spikes: epoch %g', obj.epochIndicesList(index)));
                drawnow;
                obj.detectSpikes(index);
            end
            
            if obj.handles.autoSaveCheckbox.Value
                saveAndSyncCellData(obj.cellData);
            end
            
            obj.updateUI();
        end

        function updateFutureSpikeTimes(obj)
            for index=1:length(obj.epochIndicesList)
                
                if index < obj.curEpochListIndex
                    continue
                end
%                 set(obj.fig, 'Name', sprintf('Detecting spikes: epoch %g', obj.epochIndicesList(index)));
                drawnow;
                obj.detectSpikes(index);
            end
            
            if obj.handles.autoSaveCheckbox.Value
                saveAndSyncCellData(obj.cellData);
            end
            
            obj.updateUI();
        end        
        
        function loadCurrentEpochResponse(obj)
            epoch = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex));
            obj.sampleRate = epoch.get('sampleRate');
            obj.data = epoch.getData(obj.streamName);
            obj.data = obj.data - mean(obj.data);
            obj.data = obj.data';
            
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
        
            if obj.handles.autoSaveCheckbox.Value
                saveAndSyncCellData(obj.cellData);
            end
            obj.updateUI();
            
        end
        
        function selectValidSpikes(obj)
            selection = getrect(obj.handles.ax);
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
            
            if obj.handles.autoSaveCheckbox.Value
                saveAndSyncCellData(obj.cellData);
            end
            obj.updateUI();
        end
        
        function saveNow(obj)
            saveAndSyncCellData(obj.cellData);
            disp('Saved');
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
            t = (0:length(obj.data)-1) / obj.sampleRate;
            plot(obj.handles.ax, t, obj.data, 'k');
            hold(obj.handles.ax, 'on');
            plot(obj.handles.ax, t(obj.spikeTimes), obj.data(obj.spikeTimes), 'ro', 'MarkerSize', 10, 'linewidth', 2);
            if strcmp(obj.mode, 'Simple threshold')
                xax = xlim();
                line(xax, [1,1]*obj.threshold, 'LineStyle', '--');
            end
            hold(obj.handles.ax, 'off');
            xlim(obj.handles.ax, [min(t), max(t)]);
            displayName = obj.cellData.epochs(obj.epochIndicesList(obj.curEpochListIndex)).get('displayName');
            set(obj.fig, 'Name',['Spike Detector: Epoch ' num2str(obj.epochIndicesList(obj.curEpochListIndex)) ' (' displayName '): ' num2str(length(obj.spikeTimes)) ' spikes']);
            
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