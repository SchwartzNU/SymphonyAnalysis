function [spikeAmps, spikeTimes, averageWaveform] = getSpikeAmplitudesForEpochs(cellData, epochIDs, deviceName)
if nargin < 3
    deviceName = 'Amplifier_Ch1';
end
L = length(epochIDs);
averageWaveform = zeros(1, 41);
for i=1:L
    data = cellData.epochs(epochIDs(i)).getData;
    spikeTimes{i} = cellData.epochs(epochIDs(i)).getSpikes(deviceName);
    [spikeAmps{i}, curAvgWaveform] = getSpikeAmplitudes(data, spikeTimes{i});
    averageWaveform = averageWaveform + length(spikeTimes{i}) .* curAvgWaveform;    
end

averageWaveform = averageWaveform./range(averageWaveform);