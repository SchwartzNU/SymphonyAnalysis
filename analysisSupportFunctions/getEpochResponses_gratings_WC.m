function outputStruct = getEpochResponses_gratings_WC(cellData, epochInd, varargin)
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

sampleRate = sampleEpoch.get('sampleRate');
[data, xvals] = sampleEpoch.getData(ip.Results.DeviceName);
%set up intervals
baselineStart = xvals(1);
baselineEnd = ip.Results.BaselineTime * 1E-3;

responseIntverval = xvals >= intervalStart & xvals < intervalEnd;
baselineInterval = xvals < ip.Results.BaselineTime * 1E-3;
postInterval = xvals >= intervalEnd;
responseIntervalLen = intervalEnd - intervalStart; %s
baselineIntervalLen = baselineEnd - baselineStart; %s
postIntervalLen = xvals(end) - intervalEnd; %s

Mstim = zeros(L, sum(responseIntverval)); %full data matrix, baseline subrtacted on each epoch
Mpost = zeros(L, sum(postInterval)); %full data matrix, baseline subrtacted on each epoch
MstimToEnd = zeros(L, sum(responseIntverval) + sum(postInterval));
baselineVal = zeros(1,L);

for i=1:L
    curEpoch = cellData.epochs(epochInd(i));
    %get data
    [data, xvals, units] = curEpoch.getData(ip.Results.DeviceName);    

    baselineData = data(baselineInterval);
    baselineVal(i) = mean(baselineData);
    
    data = LowPassFilter(data, ip.Results.LowPassFreq, 1/sampleRate);
    %baseline subtraction
    data = data - baselineVal(i);
    stimData = data(responseIntverval);
    postData = data(postInterval);    
 
    Mstim(i,:) = stimData;   
    Mstim_baselineSubtracted(i,:) = stimData - baselineVal(i);
    Mpost(i,:) = postData;
    stimToEndData = [stimData postData];
    MstimToEnd(i,:) = stimToEndData;
    
end

%loop over epochs to calculate responses
for i=1:L
    %TODO: deal with missing "value" fields as NaN throughout (or fill them
    %in as such at the end)
    if i==1 %some stuff we only need to do once: units and types for each output
        
        outputStruct.baseline.units = units;
        outputStruct.baseline.type = 'byEpoch';
        %value already set

        outputStruct.cycleAvg_x.units = 's';
        outputStruct.cycleAvg_x.type = 'combinedAcrossEpochs';
        outputStruct.cycleAvg_x.value = [];     
        
        outputStruct.cycleAvg_y.units = units;
        outputStruct.cycleAvg_y.type = 'combinedAcrossEpochs';
        outputStruct.cycleAvg_y.value = [];
        
        outputStruct.minCycleAvg.units = units;
        outputStruct.minCycleAvg.type = 'combinedAcrossEpochs';
        outputStruct.minCycleAvg.value = [];
        
        outputStruct.F0amplitude.units = 'pA';
        outputStruct.F0amplitude.type = 'singleValue';
        outputStruct.F0amplitude.value = NaN;
        
        outputStruct.F1amplitude.units = 'pA/s^2'; %?
        outputStruct.F1amplitude.type = 'singleValue';
        outputStruct.F1amplitude.value = NaN;
        
        outputStruct.F2amplitude.units = 'pA/s^2'; %?
        outputStruct.F2amplitude.type = 'singleValue';
        outputStruct.F2amplitude.value = NaN;
        
        outputStruct.F2overF1.units = '';
        outputStruct.F2overF1.type = 'singleValue';
        outputStruct.F2overF1.value = NaN;
        
    end
    
end

%baseline 
outputStruct.baseline.value = mean(baselineVal);

%meanTrace_stim = mean(Mstim_baselineSubtracted, 1);
meanTrace_stim = mean(Mstim, 1);
xvals = [0:length(meanTrace_stim)] ./ sampleRate;

freq = sampleEpoch.get('temporalFreq'); %Hz
startDelayBins = floor(sampleEpoch.get('movementDelay') / sampleRate);
cyclePts = floor(sampleRate/freq);
numCycles = floor(length(meanTrace_stim) / cyclePts);

% Get the average cycle.
cycles = zeros(numCycles, cyclePts);
for j = 1 : numCycles
    index = startDelayBins + round(((j-1)*cyclePts + (1 : floor(cyclePts))));
    cycles(j,:) =  meanTrace_stim(index);
end
% Take the mean, skipping first cycle
avgCycle = mean(cycles(2:end,:),1);
outputStruct.cycleAvg_y.value = avgCycle;
outputStruct.cycleAvg_x.value = xvals(1:length(avgCycle));
outputStruct.minCycleAvg.value = min(outputStruct.cycleAvg_y.value);

% Do the FFT.
ft = fft(avgCycle);
% Pull out the F0, F1 and F2 amplitudes.
outputStruct.F0amplitude.value = abs(ft(1))/length(ft);
outputStruct.F1amplitude.value = abs(ft(2))/length(ft)*2;
outputStruct.F2amplitude.value = abs(ft(3))/length(ft)*2;
outputStruct.F2overF1.value = abs(ft(3))/abs(ft(2));


