classdef SpikeDetectorGUI < handle
    properties
        fig
        handles
        mode
        threshold
        spikeTimes
        data
        cellData
        epochInd
        curEpochInd
        sampleRate
        streamName
        epochsInDataSets
    end
    
    methods
        function obj = SpikeDetectorGUI(cellData, epochInd, params, streamName)
            if nargin < 4
                obj.streamName = 'Amplifier_Ch1';
            else
                obj.streamName = streamName;
            end
            
            obj.cellData = cellData;
            obj.epochInd = epochInd;
            obj.mode = params.spikeDetectorMode;
            obj.threshold = params.spikeThreshold;            
            obj.curEpochInd = 1;
            obj.initializeEpochsInDataSetsList();
            obj.epochInd = sort(unique(obj.epochsInDataSets));
            
            obj.buildUI();
            
            obj.loadData();
            obj.updateSpikeTimes();
            obj.updateUI();
        end
        
        function buildUI(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['Spike Detector: Epoch ' num2str(obj.epochInd(obj.curEpochInd))], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ...
                'Position', [0 0.4*bounds(4), 0.75*bounds(3), 0.25*bounds(4)], ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt));
            
            L_main = uiextras.VBox('Parent', obj.fig);
            L_info = uiextras.HBox('Parent', L_main, ...
                'Spacing', 10);
            detectorModeText = uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Spike detector mode');
            obj.handles.detectorModeMenu = uicontrol('Parent', L_info, ...
                'Style', 'popupmenu', ...
                'String', {'Standard deviations above noise', 'Simple threshold'}, ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes());
            if strcmp(obj.mode, 'Stdev')
                set(obj.handles.detectorModeMenu, 'value', 1);
            else
                set(obj.handles.detectorModeMenu, 'value', 2);
            end
            thresholdText = uicontrol('Parent', L_info, ...
                'Style', 'text', ...
                'String', 'Threshold: ');
            obj.handles.thresholdEdit = uicontrol('Parent', L_info, ...
                'Style', 'edit', ...
                'String', num2str(obj.threshold), ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes());
            obj.handles.reDetectButton = uicontrol('Parent', L_info, ...
                'Style', 'pushbutton', ...
                'String', 'Re-detect spikes', ...
                'Callback', @(uiobj, evt)obj.updateSpikeTimes());
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
            set(L_info, 'Sizes', [-1, -1, -1, -1, -1, -1, -1, -.5, -.5]);
            obj.handles.ax = axes('Parent', L_main, ...
                'ButtonDownFcn', @axisZoomCallback);
            set(L_main, 'Sizes', [40, -1]);
        end
        
        function updateSpikeTimes(obj)
            if isSpikeEpoch(obj.cellData.epochs(obj.epochInd(obj.curEpochInd)), obj.streamName)
                ind = get(obj.handles.detectorModeMenu, 'value');
                s = get(obj.handles.detectorModeMenu, 'String');
                obj.mode = s{ind};
                obj.threshold = str2double(get(obj.handles.thresholdEdit, 'String'));
                
                if strcmp(obj.mode, 'Simple threshold')
                    obj.spikeTimes = getThresCross(obj.data,obj.threshold,sign(obj.threshold));
                elseif strcmp(obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('ampMode'), 'Cell attached')
                    spikeResults = SpikeDetector_simple(obj.data, 1./obj.sampleRate, obj.threshold);
                    obj.spikeTimes = spikeResults.sp;
                else %different spike dtector for Iclamp data
                    spikeResults = SpikeDetector_simple_Iclamp(obj.data, 1./obj.sampleRate, obj.threshold);
                    obj.spikeTimes = spikeResults.sp;
                end
                
                if strcmp(obj.streamName, 'Amplifier_Ch1')
                    obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).attributes('spikes_ch1') = obj.spikeTimes;
                else
                    obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).attributes('spikes_ch2') = obj.spikeTimes;
                end
            else
                obj.spikeTimes = [];
            end
            %remove double-counted spikes
            if  length(obj.spikeTimes) >= 2
                ISItest = diff(obj.spikeTimes);
                obj.spikeTimes = obj.spikeTimes([(ISItest > 0.0015) true]);
            end
            saveAndSyncCellData(obj.cellData) %save cellData file
            obj.updateUI();
        end
        
        function updateAllSpikeTimes(obj)
            ind = get(obj.handles.detectorModeMenu, 'value');
            s = get(obj.handles.detectorModeMenu, 'String');
            obj.mode = s{ind};
            obj.threshold = str2double(get(obj.handles.thresholdEdit, 'String'));
            
            set(obj.fig, 'Name', 'Busy...');
            drawnow;
            for i=1:length(obj.epochInd)
              if isSpikeEpoch(obj.cellData.epochs(obj.epochInd(i)), obj.streamName)
                    data = obj.cellData.epochs(obj.epochInd(i)).getData(obj.streamName);
                    data = data - mean(data);
                    data = data';
                    
                    if strcmp(obj.mode, 'Simple threshold')
                        spikeTimes = getThresCross(data,obj.threshold,sign(obj.threshold));
                    elseif strcmp(obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('ampMode'), 'Cell attached')
                        spikeResults = SpikeDetector_simple(data, 1./obj.sampleRate, obj.threshold);
                        spikeTimes = spikeResults.sp;
                    else
                        spikeResults = SpikeDetector_simple_Iclamp(data, 1./obj.sampleRate, obj.threshold);
                        spikeTimes = spikeResults.sp;
                    end
                    
                    %remove double-counted spikes
                    if  length(spikeTimes) >= 2
                        ISItest = diff(spikeTimes);
                        spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
                    end
                    
                    if i==obj.curEpochInd
                        obj.spikeTimes = spikeTimes;
                    end
                    
                    if strcmp(obj.streamName, 'Amplifier_Ch1')
                        obj.cellData.epochs(obj.epochInd(i)).attributes('spikes_ch1') = spikeTimes;
                    else
                        obj.cellData.epochs(obj.epochInd(i)).attributes('spikes_ch2') = spikeTimes;
                    end
                end
            end
            saveAndSyncCellData(obj.cellData) %save cellData file);
            obj.updateUI();
        end

        % TERRIBLE CODE DUPLICATION -sam
        function updateFutureSpikeTimes(obj)
            ind = get(obj.handles.detectorModeMenu, 'value');
            s = get(obj.handles.detectorModeMenu, 'String');
            obj.mode = s{ind};
            obj.threshold = str2double(get(obj.handles.thresholdEdit, 'String'));
            
            set(obj.fig, 'Name', 'Busy...');
            drawnow;
            for i=1:length(obj.epochInd)
              if i < obj.curEpochInd % this is the only unique part here
                  continue
              end
              if isSpikeEpoch(obj.cellData.epochs(obj.epochInd(i)), obj.streamName)
                    data = obj.cellData.epochs(obj.epochInd(i)).getData(obj.streamName);
                    data = data - mean(data);
                    data = data';
                    
                    if strcmp(obj.mode, 'Simple threshold')
                        spikeTimes = getThresCross(data,obj.threshold,sign(obj.threshold));
                    elseif strcmp(obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('ampMode'), 'Cell attached')
                        spikeResults = SpikeDetector_simple(data, 1./obj.sampleRate, obj.threshold);
                        spikeTimes = spikeResults.sp;
                    else
                        spikeResults = SpikeDetector_simple_Iclamp(data, 1./obj.sampleRate, obj.threshold);
                        spikeTimes = spikeResults.sp;
                    end
                    
                    %remove double-counted spikes
                    if  length(spikeTimes) >= 2
                        ISItest = diff(spikeTimes);
                        spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
                    end
                    
                    if i==obj.curEpochInd
                        obj.spikeTimes = spikeTimes;
                    end
                    
                    if strcmp(obj.streamName, 'Amplifier_Ch1')
                        obj.cellData.epochs(obj.epochInd(i)).attributes('spikes_ch1') = spikeTimes;
                    else
                        obj.cellData.epochs(obj.epochInd(i)).attributes('spikes_ch2') = spikeTimes;
                    end
                end
            end
            saveAndSyncCellData(obj.cellData) %save cellData file);
            obj.updateUI();
        end        
        
        function loadData(obj)
            obj.sampleRate = obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('sampleRate');
            obj.data = obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).getData(obj.streamName);
            obj.data = obj.data - mean(obj.data);
            obj.data = obj.data';
            
            
            %load spike times if they are present
            if strcmp(obj.streamName, 'Amplifier_Ch1')
                if ~isnan(obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('spikes_ch1'))
                    obj.spikeTimes = obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('spikes_ch1');
                else
                    obj.updateSpikeTimes();
                end
            else
                if ~isnan(obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('spikes_ch2'))
                    obj.spikeTimes = obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('spikes_ch2');
                else
                    obj.updateSpikeTimes();
                end
            end
            
            obj.updateUI();
        end
        
        function skipBackward10(obj)
            obj.curEpochInd = max(obj.curEpochInd-10, 1);
            obj.loadData();
        end
        function skipForward10(obj)
            obj.curEpochInd = min(obj.curEpochInd+10, length(obj.epochInd));
            obj.loadData();
        end
        
        function initializeEpochsInDataSetsList(obj)
           k = obj.cellData.savedDataSets.keys;
           for i=1:length(k)
               obj.epochsInDataSets = [obj.epochsInDataSets obj.cellData.savedDataSets(k{i})];
           end
        end
        
        function updateUI(obj)
            plot(obj.handles.ax, 1:length(obj.data), obj.data, 'k');
            hold(obj.handles.ax, 'on');
            plot(obj.handles.ax, obj.spikeTimes, obj.data(obj.spikeTimes), 'rx');
            hold(obj.handles.ax, 'off');
            displayName = obj.cellData.epochs(obj.epochInd(obj.curEpochInd)).get('displayName');
            set(obj.fig, 'Name',['Spike Detector: Epoch ' num2str(obj.epochInd(obj.curEpochInd)) ' (' displayName '): ' num2str(length(obj.spikeTimes)) ' spikes']);
        end
        
        function keyHandler(obj, evt)
            switch evt.Key
                case 'leftarrow'
                    obj.curEpochInd = max(obj.curEpochInd-1, 1);
                    obj.loadData();
                case 'rightarrow'
                    obj.curEpochInd = min(obj.curEpochInd+1, length(obj.epochInd));
                    obj.loadData();
                case 'escape'
                    delete(obj.fig);
                otherwise
                    %disp(evt.Key);
            end
        end
        
    end
    
end