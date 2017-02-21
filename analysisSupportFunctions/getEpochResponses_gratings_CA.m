function outputStruct = getEpochResponses_gratings_CA(cellData, epochInd, varargin)
ip = inputParser;
ip.KeepUnmatched = true;
ip.addParamValue('DeviceName', 'Amplifier_Ch1', @(x)ischar(x));
ip.addParamValue('BaselineTime', 0, @(x)isnumeric(x)); %ms - overrides preTime for baseline interval calculation, use if preTime is missing
ip.addParamValue('StartTime', 0, @(x)isnumeric(x)); %ms with 0 as stimulus start time
ip.addParamValue('EndTime', 0, @(x)isnumeric(x)); %ms
ip.addParamValue('LowPassFreq', 30, @(x)isnumeric(x)); %Hz
ip.addParamValue('BinWidth', 10, @(x)isnumeric(x)); %ms
ip.addParamValue('EndOffset', 0, @(x)isnumeric(x)); %ms

ip.parse(varargin{:});

L = length(epochInd);

sampleEpoch = cellData.epochs(epochInd(1));

intervalStart = ip.Results.StartTime * 1E-3; %s
if ip.Results.EndTime == 0 %default to end at stimEnd
    intervalEnd = (sampleEpoch.get('stimTime') + ip.Results.EndOffset) * 1E-3; %s
else
    intervalEnd = ip.Results.EndTime * 1E-3; %s
end

%first pass through epochsis for getting baseline spikes, ISIs.
%These will be used later for figuring out the response probability

blISI = cell(1,L); %initialize ISI dist
blISI2 = cell(1,L);
fullISI = [];
fullSpikeAmpDiff = [];
for i=1:L
    curEpoch = cellData.epochs(epochInd(i));
    
    if i==1 %some stuff we only need to do once
        sampleRate = curEpoch.get('sampleRate');
        [~, xvals] = curEpoch.getData(ip.Results.DeviceName);
        [~, stimStart] = min(abs(xvals)); %closest point to zero
        stimStart = stimStart(1);
        %set up intervals for spike counting
        baselineStart = xvals(1);
        baselineEnd = ip.Results.BaselineTime * 1E-3;
        %         responseIntverval = xvals >= intervalStart & xvals < intervalEnd;
        %         baselineInterval = xvals < ip.Results.BaselineTime * 1E-3;
        responseIntervalLen = intervalEnd - intervalStart; %s
        baselineIntervalLen = baselineEnd - baselineStart; %s
    end
    
    %get spike times (in units of seconds from startTime
    spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName);
    spikeTimes = spikeTimes - stimStart;
    spikeTimes = spikeTimes / sampleRate;
    
    %TEMP HACK: This is to remove crazy refractory preiod violations from the spike detector
    if  length(spikeTimes) >= 2
        ISItest = diff(spikeTimes);
        spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
    end;
    
    %get baseline spikes
    baselineSpikeTimes = spikeTimes(spikeTimes < baselineEnd);
    outputStruct.baselineRate.value(i) = length(baselineSpikeTimes) / baselineIntervalLen;
end


%get meanBaseline: to be used throughout
meanBaselineRate = mean(outputStruct.baselineRate.value);

%initalize a few things
ONSETresponseStartTime_all = ones(1,L) * NaN;
ONSETresponseEndTime_all = ones(1,L) * NaN;
OFFSETresponseStartTime_all = ones(1,L) * NaN;
OFFSETresponseEndTime_all = ones(1,L) * NaN;

%loop over epochs to calculate responses
for i=1:L
    %TODO: deal with missing "value" fields as NaN throughout (or fill them
    %in as such at the end)
    if i==1 %some stuff we only need to do once: units and types for each output
        
        outputStruct.baselineRate.units = 'Hz';
        outputStruct.baselineRate.type = 'byEpoch';
        %value already set

        outputStruct.cycleAvgPSTH_x.units = 's';
        outputStruct.cycleAvgPSTH_x.type = 'combinedAcrossEpochs';
        outputStruct.cycleAvgPSTH_x.value = [];     
        
        outputStruct.cycleAvgPSTH_y.units = 'Hz';
        outputStruct.cycleAvgPSTH_y.type = 'combinedAcrossEpochs';
        outputStruct.cycleAvgPSTH_y.value = []; 
        
        outputStruct.F0amplitude.units = 'Hz';
        outputStruct.F0amplitude.type = 'singleValue';
        outputStruct.F0amplitude.value = NaN;
        
        outputStruct.F1amplitude.units = 'Hz/s^2'; %?
        outputStruct.F1amplitude.type = 'singleValue';
        outputStruct.F1amplitude.value = NaN;
        
        outputStruct.F2amplitude.units = 'Hz/s^2'; %?
        outputStruct.F2amplitude.type = 'singleValue';
        outputStruct.F2amplitude.value = NaN;
        
        outputStruct.F2overF1.units = '';
        outputStruct.F2overF1.type = 'singleValue';
        outputStruct.F2overF1.value = NaN;
  
        %Adam 2/13/17
        outputStruct.cycleAvgPeakFR.units = 'Hz';
        outputStruct.cycleAvgPeakFR.type = 'singleValue';
        outputStruct.cycleAvgPeakFR.value = [];    
        
        
    end
    
    
    
end

[psth, xvals] = cellData.getPSTH(epochInd, ip.Results.BinWidth, ip.Results.DeviceName);
sampleEpoch = cellData.epochs(epochInd(1));
sampleRate = sampleEpoch.get('sampleRate');
binWidth = 10; %ms
%get bins
samplesPerMS = sampleRate/1E3;
samplesPerBin = binWidth*samplesPerMS;

freq = sampleEpoch.get('temporalFreq'); %Hz
startDelayBins = floor(sampleEpoch.get('movementDelay') / binWidth);
cyclePts = floor(sampleRate/samplesPerBin/freq);
numCycles = floor((length(psth) - startDelayBins) / cyclePts);

% Get the average cycle.
cycles = zeros(numCycles, cyclePts);
for j = 1 : numCycles
    index = startDelayBins + round(((j-1)*cyclePts + (1 : floor(cyclePts))));
    cycles(j,:) =  psth(index);
end
% Take the mean, skipping first cycle
avgCycle = mean(cycles(2:end, :),1);
outputStruct.cycleAvgPSTH_y.value = avgCycle;
outputStruct.cycleAvgPSTH_x.value = xvals(1:length(avgCycle));
% Do the FFT.
ft = fft(avgCycle);
% figure(10)
% subplot(3,1,1)
% plot(psth)
% subplot(3,1,2)
% plot(avgCycle)
% subplot(3,1,3)
% plot(abs(ft))

% Pull out the F1 and F2 amplitudes.
outputStruct.F0amplitude.value = abs(ft(1))/length(ft);
outputStruct.F1amplitude.value = abs(ft(2))/length(ft)*2;
outputStruct.F2amplitude.value = abs(ft(3))/length(ft)*2;
outputStruct.F2overF1.value = abs(ft(3))/abs(ft(2));

%Adam 2/13/17
outputStruct.cycleAvgPeakFR.value = max(avgCycle); 
