function v = isSpikeEpoch(epoch, streamName)
v = false;
if strcmp(streamName, 'Amplifier_Ch1')
    if strcmp(epoch.get('ampMode'), 'Cell attached')
        v = true;
    elseif strcmp(epoch.get('ampMode'), 'Whole cell') && (epoch.get('ampHoldSignal') == 0) %current clamp recording might have spikes
        v = true;
    end
elseif strcmp(streamName, 'Amplifier_Ch2')
    if strcmp(epoch.get('amp2Mode'), 'Cell attached')
        v = true;
    elseif strcmp(epoch.get('ampMode'), 'Whole cell') && (epoch.get('amp2HoldSignal') == 0) 
        v = true;
    end
else
    disp(['Error in isSpikeEpoch: unknown stream name ' streamName]);
end