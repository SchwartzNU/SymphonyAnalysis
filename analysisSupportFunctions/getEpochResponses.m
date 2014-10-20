function [resp, respUnits, returnLen] = getEpochResponses(cellData, epochInd, responseType, varargin)
ip = inputParser;
ip.KeepUnmatched = true;
ip.addParamValue('DeviceName', 'Amplifier_Ch1', @(x)ischar(x));
ip.addParamValue('BaselineTime', 0, @(x)isnumeric(x)); %ms - overrides preTime for baseline interval calculation, use if preTime is missing
ip.addParamValue('StartTime', 0, @(x)isnumeric(x)); %ms with 0 as stimulus start time
ip.addParamValue('EndTime', 0, @(x)isnumeric(x)); %ms
ip.addParamValue('LowPassFreq', 100, @(x)isnumeric(x)); %Hz
ip.addParamValue('BinWidth', 10, @(x)isnumeric(x)); %ms
ip.addParamValue('EndOffset', 0, @(x)isnumeric(x)); %ms

ip.parse(varargin{:});

L = length(epochInd);
resp = zeros(1,L);

sampleEpoch = cellData.epochs(epochInd(1));
if strcmp(ip.Results.DeviceName, 'Amplifier_Ch1')
    recordingMode = sampleEpoch.get('ampMode');
elseif strcmp(ip.Results.DeviceName, 'Amplifier_Ch2')
    recordingMode = sampleEpoch.get('amp2Mode');
else
    disp(['Error: unrecognized device ' ip.Results.DeviceName]);
    return
end

intervalStart = ip.Results.StartTime * 1E-3; %s
if ip.Results.EndTime == 0 %default to end at stimEnd
    intervalEnd = (sampleEpoch.get('stimTime') + ip.Results.EndOffset) * 1E-3; %s
else
    intervalEnd = ip.Results.EndTime * 1E-3; %s
end

for i=1:L
    curEpoch = cellData.epochs(epochInd(i));
    
    %get data
    sampleRate = curEpoch.get('sampleRate');
    spikeTimes = [];
    [data, xvals, units] = curEpoch.getData(ip.Results.DeviceName);
    if strcmp(recordingMode, 'Cell attached')
        spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName);
        [~, stimStart] = min(abs(xvals)); %closest point to zero
        stimStart = stimStart(1);
        spikeTimes = spikeTimes - stimStart;
        spikeTimes = spikeTimes / sampleRate;
    end
    
    
    baselineStart = xvals(1);
    baselineEnd = ip.Results.BaselineTime * 1E-3;
    
    responseIntverval = xvals >= intervalStart & xvals < intervalEnd;
    baselineInterval = xvals < ip.Results.BaselineTime * 1E-3;
    responseIntervalLen = intervalEnd - intervalStart; %s
    baselineIntervalLen = baselineEnd - baselineStart; %s
    
    if ~strcmp(recordingMode, 'Cell attached')
        stimData = data(responseIntverval);
        baselineData = data(baselineInterval);
    end
    
    switch responseType
        case 'Baseline spikes'
            baselineSpikes = length(find(spikeTimes < baselineEnd));
            resp(i) = baselineSpikes;
            respUnits = 'spikes';
            returnLen = baselineIntervalLen;
            
        case 'Spike count'
            %count spikes in stimulus interval
            spikeCount = length(find(spikeTimes >= intervalStart & spikeTimes < intervalEnd));
            %subtract baseline
            %baselineSpikes = length(find(spikeTimes < baselineEnd));
            resp(i) = spikeCount;
            %- baselineSpikes*responseIntervalLen/baselineIntervalLen;
            respUnits = 'spikes';
            returnLen = responseIntervalLen;
            
        case 'Baseline firing rate'
            [psth, xvals] = cellData.getPSTH(epochInd, ip.Results.BinWidth, ip.Results.DeviceName);
            resp(i) = mean(psth(xvals < ip.Results.BaselineTime * 1E-3));
            respUnits = 'Hz';
            
        case 'Peak firing rate' %this is kind of wrong to do this per epoch - will always give the same result
            [psth, xvals] = cellData.getPSTH(epochInd, ip.Results.BinWidth, ip.Results.DeviceName);
            %resp(i) = max(psth(xvals >= intervalStart & xvals < intervalEnd)) - mean(psth(xvals < ip.Results.BaselineTime * 1E-3)); %normalized
            resp(i) = max(psth(xvals >= intervalStart & xvals < intervalEnd)); %normalized
            respUnits = 'Hz';
            
            %        case 'CycleAvgF1'
            %             stimLen = obj.stimEnd - obj.stimStart; %samples
            %             stimSpikes = sp(sp>=obj.stimStart & sp<obj.stimEnd) - obj.stimStart; %offset to start of stim
            %             binWidth = 10; %ms
            %             %get bins
            %             samplesPerMS = sampleRate/1E3;
            %             samplesPerBin = binWidth*samplesPerMS;
            %             bins = 0:samplesPerBin:stimLen;
            %
            %             %compute PSTH for this epoch
            %             spCount = histc(sp,bins);
            %             if isempty(spCount)
            %                 spCount = zeros(1,length(bins));
            %             end
            %
            %             %convert to Hz
            %             spCount = spCount / (binWidth*1E-3);
            %
            %             freq = epoch.getParameter('frequency');
            %             cyclePts = floor(sampleRate/samplesPerBin/freq);
            %             numCycles = floor(length(spCount) / cyclePts);
            %
            %             % Get the average cycle.
            %             cycles = zeros(numCycles, cyclePts);
            %             for j = 1 : numCycles
            %                 index = round(((j-1)*cyclePts + (1 : floor(cyclePts))));
            %                 cycles(j,:) =  spCount(index);
            %             end
            %             % Take the mean.
            %             avgCycle = mean(cycles,1);
            %
            %             % Do the FFT.
            %             ft = fft(avgCycle);
            %
            %             % Pull out the F1 amplitude.
            %             responseVal = abs(ft(2))/length(ft)*2;
            
        case 'Peak'
            stimData = LowPassFilter(stimData, ip.Results.LowPassFreq, 1/sampleRate);
            stimData = stimData - mean(baselineData);
            if abs(max(stimData)) > abs(min(stimData))
                resp(i) = max(stimData);
            else
                resp(i) = min(stimData);
            end
            respUnits = units;
            
        case 'Abs Peak'
            stimData = LowPassFilter(stimData, ip.Results.LowPassFreq, 1/sampleRate);
            stimData = stimData - mean(baselineData);
            resp(i) = max(abs(stimData));
            respUnits = units;
            
        case 'Charge'
            resp(i) = sum(stimData - mean(baselineData)) * responseIntervalLen / sampleRate;
            respUnits = 'pC';
            
        case 'Abs Charge'
            resp(i) = abs(sum(stimData - mean(baselineData)) * responseIntervalLen / sampleRate);
            respUnits = 'pC';
            
        case 'CycleAvgF1'
            freq = curEpoch.get('frequency');
            cyclePts = floor(sampleRate/freq);
            numCycles = floor(length(stimData) / cyclePts);
            
            % Get the average cycle.
            cycles = zeros(numCycles, cyclePts);
            for j = 1 : numCycles
                index = round(((j-1)*cyclePts + (1 : floor(cyclePts))));
                cycles(j,:) =  stimData(index);
            end
            % Take the mean.
            avgCycle = mean(cycles,1);
            
            % Do the FFT.
            ft = fft(avgCycle);
            
            % Pull out the F1 amplitude.
            resp(i) = abs(ft(2))/length(ft)*2;
            respUnits = 'pA^2/Hz'; %? I'm not sure this is scaled correctly for these units
    end
end


