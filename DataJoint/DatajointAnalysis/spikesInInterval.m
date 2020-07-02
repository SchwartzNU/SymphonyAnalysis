function spike_count = spikesInInterval(spike_train, startTime, endTime, zeroParam)
%spike_train is a SpikeTrain object
%startTime and endTime are in seconds
%Leave either or both empty to go to start or end of epoch 
%zeroParam is the name of a parameter to be used to set the zero time
%Units in this parameter are ms. This is optional.

ep = sl.Epoch & spike_train;
sample_rate = fetch1(ep, 'sample_rate');
cell_data = fetch1(ep, 'cell_data');
ep_num = fetch1(ep, 'number');
sp = fetch1(spike_train, 'sp');

spike_count = nan;
zeroTime_ms = 0;

if ischar(sp) %not a real spike train
    disp(['spikesInInterval: ' cell_data ': epoch ' num2str(ep_num) 'spikeTrain = ' sp]);
    return;
else
    sp = sp / sample_rate; %now in seconds
    if nargin == 4 %zeroParam defined
        protocol_params = fetch1(ep, 'protocol_params');
        if isfield(protocol_params, zeroParam)
            zeroTime_ms = protocol_params.(zeroParam);
            if ~isnan(zeroTime_ms)
                sp = sp - zeroTime_ms / 1E3; %ms to s
            else
                disp(['spikesInInterval: ' cell_data ': epoch ' num2str(ep_num) ': ' zeroParam ' = nan']);
                return;
            end
        else
            disp(['spikesInInterval: ' cell_data ': epoch ' num2str(ep_num) ': ' zeroParam ' not found']);
            return;
        end
    end    
end

if isempty(startTime) 
    startTime = -zeroTime_ms / 1E3; %ms to s;
end

if isempty(endTime)
    endTime = max(startTime, max(sp));
end

spike_count = sum(sp > startTime & sp <= endTime);






