classdef ShapeData
    
    properties
        ampMode
        sampleRate
        
        spikes       
        spikeRate
        t
        response

        spotTotalTime
        spotOnTime
        numSpots
        
        shapeDataMatrix
        shapeDataColumns
    end
    
    methods
        function obj = ShapeData(epoch, runmode)
            
            obj.sampleRate = 1000;
            
            % standard parameters in epoch
            if strcmp(runmode, 'offline')
                sdc = epoch.get('shapeDataColumns');
                sd = epoch.get('shapeData');
                obj.spotTotalTime = epoch.get('spotTotalTime');
                obj.spotOnTime = epoch.get('spotOnTime');
                obj.numSpots = epoch.get('numSpots');
                obj.ampMode = epoch.get('ampMode');
            else
                sdc = epoch.getParameter('shapeDataColumns');
                sd = epoch.getParameter('shapeData');
                obj.spotTotalTime = epoch.getParameter('spotTotalTime');
                obj.spotOnTime = epoch.getParameter('spotOnTime');
                obj.numSpots = epoch.getParameter('numSpots');
                obj.ampMode = epoch.getParameter('ampMode');
            end
            
            % process shape data from epoch
            obj.shapeDataColumns = containers.Map;
            if ~isnan(sdc)
                txt = strsplit(char(sdc), ',');
                obj.shapeDataColumns('intensity') = find(not(cellfun('isempty', strfind(txt, 'intensity'))));
                obj.shapeDataColumns('X') = find(not(cellfun('isempty', strfind(txt, 'X'))));
                obj.shapeDataColumns('Y') = find(not(cellfun('isempty', strfind(txt, 'Y'))));
                num_cols = length(obj.shapeDataColumns);
                shapeData = reshape(str2num(char(sd)), [], num_cols);
            else
                % handle old-style epochs with positions
                obj.shapeDataColumns('X') = 1;
                obj.shapeDataColumns('Y') = 2;
                obj.shapeDataColumns('intensity') = 3;
                shapeData = reshape(str2num(char(epoch.get('positions'))), [], 2);
                shapeData = horzcat(shapeData, ones(length(shapeData),1));
            end
            obj.shapeDataMatrix = shapeData;
            
            
            % process actual response or spikes from epoch
            if strcmp(runmode, 'offline')
            if strcmp(obj.ampMode, 'Cell attached')
                data.spikes = epoch.getSpikes();
                data.response = [];
            else
                % whole cell
                data.response = epoch.response();
                data.spikes = [];
            end
            
    end
    
end
    
    





% below might error
if strcmp(data.ampMode, 'Cell attached')
    data.spikes = epoch.getSpikes();
    data.response = [];
else
    % whole cell
    data.response = epoch.response();
    data.spikes = [];
end


function processSpikes()
    spikeRate_orig = zeros(round((data.numSpots + 1) * data.spotTotalTime * 10000), 1);
    spikeRate_orig(data.spikes) = 1.0;
    spikeRate_f = filtfilt(hann(data.sampleRate / 10), 1, spikeRate_orig); % 10 ms (100 samples) window filter
    spikeRate = resample(spikeRate_f, data.sampleRate, 10000);
    t = (0:(length(spikeRate)-1)) / data.sampleRate;
    data.spikeRate = spikeRate;
    data.t = t;
end

if ~isempty(data.spikes)
    processSpikes
else
    data.spikeRate = [];
    data.t = [];
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




end