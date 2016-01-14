classdef ShapeData < handle
    
    properties
        sessionId
        presentationId
        
        epochMode
        ampMode
        ampVoltage
        sampleRate
        preTime
        stimTime
        
        spikes       
        spikeRate
        t
        response

        spotTotalTime
        spotOnTime
        numSpots
        totalNumSpots % including values and repeats
        spotDiameter
        numValues
        numValueRepeats
        
        shapeDataMatrix
        shapeDataColumns
    end
    
    methods
        function obj = ShapeData(epoch, runmode)
            
            obj.sampleRate = 1000; %desired rate
            obj.preTime = .250; % fixed always anyway
            
            % standard parameters in epoch
            if strcmp(runmode, 'offline')
                obj.sessionId = epoch.get('sessionId');
                obj.presentationId = epoch.get('presentationId');
                sdc = epoch.get('shapeDataColumns');
                sdm = epoch.get('shapeDataMatrix');
                if ~(isa(sdm,'System.String') || isa(sdm,'char'))
                    sdm = epoch.get('shapeData');
                end
                em = epoch.get('epochMode');
                obj.spotTotalTime = epoch.get('spotTotalTime');
                obj.spotOnTime = epoch.get('spotOnTime');
                obj.spotDiameter = epoch.get('spotDiameter');
                obj.numSpots = epoch.get('numSpots');
                obj.ampMode = char(epoch.get('ampMode'));
                obj.ampVoltage = epoch.get('ampHoldSignal');
                obj.numValues = epoch.get('numValues');
                obj.numValueRepeats = epoch.get('numValueRepeats');
                obj.stimTime = epoch.get('stimTime');
                
            elseif strcmp(runmode, 'online')
                obj.sessionId = epoch.getParameter('sessionId');
                obj.presentationId = epoch.getParameter('presentationId');                
                sdc = epoch.getParameter('shapeDataColumns');
                sdm = epoch.getParameter('shapeDataMatrix');
                if ~(isa(sdm,'System.String') || isa(sdm,'char'))
                    sdm = epoch.getParameter('shapeData');
                end
                em = epoch.getParameter('epochMode');
                obj.spotTotalTime = epoch.getParameter('spotTotalTime');
                obj.spotOnTime = epoch.getParameter('spotOnTime');
                obj.spotDiameter = epoch.getParameter('spotDiameter');
                obj.numSpots = epoch.getParameter('numSpots');
                obj.ampMode = char(epoch.getParameter('ampMode'));
                obj.ampVoltage = epoch.getParameter('ampHoldSignal');                
                obj.numValues = epoch.getParameter('numValues');
                obj.numValueRepeats = epoch.getParameter('numValueRepeats');
                obj.stimTime = epoch.getParameter('stimTime');
            end
            
            % process shape data from epoch
            obj.shapeDataColumns = containers.Map;
            newColumnsNames = {};
            newColumnsData = [];
            % collect what data we have to make the ShapeDataMatrix
            
            % positions w/ X,Y
            if ~(isa(sdc,'System.String') || isa(sdc,'char'))
                obj.shapeDataColumns('X') = 1;
                obj.shapeDataColumns('Y') = 2;
                obj.shapeDataMatrix = reshape(str2num(char(epoch.get('positions'))), [], 2);
            else
                % shapedata w/ X,Y,intensity...
                colsTxt = strsplit(char(sdc), ',');
                obj.shapeDataColumns('intensity') = find(not(cellfun('isempty', strfind(colsTxt, 'intensity'))));
                obj.shapeDataColumns('X') = find(not(cellfun('isempty', strfind(colsTxt, 'X'))));
                obj.shapeDataColumns('Y') = find(not(cellfun('isempty', strfind(colsTxt, 'Y'))));
                
                % ... startTime,endTime,diameter (also)
                if isa(em,'System.String') || isa(em,'char')
                    obj.epochMode = char(em);
                    obj.shapeDataColumns('diameter') = find(not(cellfun('isempty', strfind(colsTxt, 'diameter'))));
                    obj.shapeDataColumns('startTime') = find(not(cellfun('isempty', strfind(colsTxt, 'startTime'))));
                    obj.shapeDataColumns('endTime') = find(not(cellfun('isempty', strfind(colsTxt, 'endTime'))));
                else
                    % or need to generate those later
                    obj.epochMode = 'flashingSpots';
                end
            
                num_cols = length(obj.shapeDataColumns);
                obj.shapeDataMatrix = reshape(str2num(char(sdm)), [], num_cols); %#ok<*ST2NM>
%                 disp(obj.shapeDataMatrix)
            end
            
            obj.totalNumSpots = size(obj.shapeDataMatrix,1);
            
            % add columns that we don't have
            if ~isKey(obj.shapeDataColumns, 'intensity')
                newColumnsNames{end+1} = 'intensity';
                newColumnsData = horzcat(newColumnsData, ones(length(obj.shapeDataMatrix),1));
            end
            
            if ~isKey(obj.shapeDataColumns, 'startTime')
                si = (1:obj.totalNumSpots)';
                startTime = (si - 1) * obj.spotTotalTime;
                endTime = startTime + obj.spotOnTime;
                newColumnsNames{end+1} = 'startTime';
                newColumnsNames{end+1} = 'endTime';
                newColumnsData = horzcat(newColumnsData, startTime, endTime);
            end
                                
            if ~isKey(obj.shapeDataColumns, 'diameter')
                newColumnsData = horzcat(newColumnsData, obj.spotDiameter * ones(length(obj.shapeDataMatrix),1));
                newColumnsNames{end+1} = 'diameter';
            end

            % add new columns
            for ci = 1:length(newColumnsNames)
                name = newColumnsNames{ci};
                obj.shapeDataMatrix = horzcat(obj.shapeDataMatrix, newColumnsData(:,ci));
                obj.shapeDataColumns(name) = size(obj.shapeDataMatrix, 2);
            end

            % process actual response or spikes from epoch
            if strcmp(runmode, 'offline')
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.setSpikes(epoch.getSpikes());
                elseif strcmp(obj.ampMode, 'emulated')
                    obj.spikes = [];
                else % whole cell
                    obj.spikes = [];
                    obj.setResponse(epoch.getData('Amplifier_Ch1'));
                    obj.processWholeCell()
                end
            else
                obj.spikes = [];
                obj.response = [];
            end
        end
        
        function setResponse(obj, response)
            % downsample and generate time vector
            response = resample(response, obj.sampleRate, 10000);
            obj.response = response;
            obj.t = (0:(length(obj.response)-1)) / obj.sampleRate;
            obj.t = obj.t - obj.preTime;
        end
        
        function setSpikes(obj, spikes)
            if isnan(spikes)
                disp('No spikes found (detect them maybe?)')
            else
                obj.spikes = spikes;
                obj.processSpikes()
            end
        end
    
        function processSpikes(obj)
            % convert spike times to raw response
            
            if ~isempty(obj.spikes)
                spikeRate_orig = zeros(max(obj.spikes) + 100, 1);
                spikeRate_orig(obj.spikes) = 1.0;
                obj.spikeRate = filtfilt(hann(obj.sampleRate / 10), 1, spikeRate_orig); % 10 ms (100 samples) window filter
            else
                obj.spikeRate = 0;
            end
            obj.setResponse(obj.spikeRate)
        end
        
        function processWholeCell(obj)
            % call after setResponse to make current like spikeRate
            r = sign(obj.ampVoltage) * obj.response;
            r = r - mean(r(1:round(obj.sampleRate*obj.preTime)));
            Fstop = .05;
            Fpass = .1;
            Astop = 20;
            Apass = 0.5;
%             wc_filter = designfilt('highpassiir','StopbandFrequency',Fstop, ...
%                 'PassbandFrequency',Fpass,'StopbandAttenuation',Astop, ...
%                 'PassbandRipple',Apass,'SampleRate',obj.sampleRate,'DesignMethod','butter');
%             
%             r = filtfilt(wc_filter, r);
            
            obj.response = r;
        end
        
        function simulateSpikes(obj)
            sp = simulateSpikeTrain(obj);
            obj.setSpikes(sp);
        end
    end
end



% signalData = {};
% if strcmp(responsemode, 'ca')
%     % cell attached spikes
%     if isempty(varargin) % responses included in epochs already
%         for p = 1:num_epochs
%             epoch = epochData{p,1};
%             signalData{p,1} = epoch.getSpikes();
%         end
%     else
%         signalData = varargin{1};
%     end
% else
%     % whole cell signal
%     if isempty(varargin)
%         for p = 1:num_epochs
%             epoch = epochData{p,1};
%             [signal, ~, ~] = epoch.response();
%             signalData{p,1} = signal;
%         end
%     else
%         signalData = varargin{1};
%     end
% end
