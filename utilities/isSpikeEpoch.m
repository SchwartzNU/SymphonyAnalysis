function v = isSpikeEpoch(epoch, streamName)
v = false;
if strcmp(streamName, 'Amplifier_Ch1')
    if strcmp(epoch.get('ampMode'), 'Cell attached')
        v = true;
    elseif strcmp(epoch.get('ampMode'), 'Whole cell')
        try 
            if strcmp(epoch.get('wholeCellRecordingMode_Ch1'), 'Iclamp') % check for new epoch param
                v = true;
            end
        catch
            if (epoch.get('ampHoldSignal') == 0) %current clamp recording might have spikes
                v = true;
            end
        end
    end
elseif strcmp(streamName, 'Amplifier_Ch2')
%     v = true;
    if strcmp(epoch.get('amp2Mode'), 'Cell attached')
        v = true;
    elseif strcmp(epoch.get('amp2Mode'), 'Whole cell')
        try 
            if strcmp(epoch.get('wholeCellRecordingMode_Ch2'), 'Iclamp') % check for new epoch param
                v = true;
            end
        catch
            epoch.get('amp2HoldSignal')
            if (epoch.get('amp2HoldSignal') == 0) %current clamp recording might have spikes
                v = true;
            end
        end
    end
else
    disp(['Error in isSpikeEpoch: unknown stream name ' streamName]);
end