function outputStruct = getEpochResponses_WC_ActionCurrents(cellData, epochInd, varargin)
ip = inputParser;
ip.KeepUnmatched = true;
ip.addParamValue('DeviceName', 'Amplifier_Ch1', @(x)ischar(x));
ip.addParamValue('BaselineTime', 0, @(x)isnumeric(x)); %ms - overrides preTime for baseline interval calculation, use if preTime is missing
ip.addParamValue('StartTime', 0, @(x)isnumeric(x)); %ms with 0 as stimulus start time

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

if strcmp(recordingMode, 'Off')
    fprintf('Recording mode off (may not be data for %s)\n', ip.Results.DeviceName)
    outputStruct = struct;
    return
end

stim1Start = ip.Results.StartTime * 1E-3; %s
stim2Start = stim1Start + sampleEpoch.get('stim1Time') * 1E-3;
stim2End = stim2Start + sampleEpoch.get('stim2Time') * 1E-3;

sampleRate = sampleEpoch.get('sampleRate'); %get samplerate
[data, xvals] = sampleEpoch.getData(ip.Results.DeviceName); %get data and xvals with it (in s)

%set up intervals
baselineEnd = ip.Results.BaselineTime * 1E-3;

baselineInterval = xvals < baselineEnd;
stim1Interval = xvals >= stim1Start & xvals < stim2Start;
stim2Interval = xvals >= stim2Start & xvals < stim2End;

%currently not using these transient intervals, but we could
stim1TransInterval = xvals >= stim1Start & xvals < stim1Start + .05; % 50 ms
stim2TransInterval = xvals >= stim2Start & xvals < stim2Start + .05; % 50 ms

%baseline at end of stim 1, before stim 2 starts
stim1BaseInterval = xvals >= stim2Start - .1 & xvals < stim2Start; % 100 ms before end of stim1

Mstim1 = zeros(L, sum(stim1Interval)); %full data matrix, baseline subtracted on each epoch
Mstim2 = zeros(L, sum(stim2Interval)); %full data matrix, baseline subtracted on each epoch
Mstim1trans = zeros(L, sum(stim1TransInterval)); %full data matrix, baseline subtracted on each epoch
Mstim2trans = zeros(L, sum(stim2TransInterval)); %full data matrix, baseline subtracted on each epoch

baselineVal = zeros(1,L); %baseline in prepoints
stim1baselineVal = zeros(1,L); %steady state at the end of stim1

for i=1:L %loops over epochs
    curEpoch = cellData.epochs(epochInd(i));
    %get data
    [data, xvals, units] = curEpoch.getData(ip.Results.DeviceName);    

    baselineData = data(baselineInterval);
    baselineVal(i) = mean(baselineData);
    
    s1baselineData = data(stim1BaseInterval);
    stim1baselineVal(i) = mean(s1baselineData);
    
    %baseline subtraction
    s1_stimData = data(stim1Interval) - baselineVal(i);
    Mstim1(i,:) = s1_stimData;
    s1_stimData_trans = data(stim1TransInterval) - baselineVal(i);
    Mstim1trans(i,:) = s1_stimData_trans;
    
    s2_stimData = data(stim2Interval) - stim1baselineVal(i);
    Mstim2(i,:) = s2_stimData;
    s2_stimData_trans = data(stim2TransInterval) - stim1baselineVal(i);
    Mstim2trans(i,:) = s2_stimData_trans;
    
    if i==1 %some stuff we only need to do once: units and types for each output
        outputStruct.baseline.units = units;
        outputStruct.baseline.type = 'singleValue';
        %outputStruct.baseline.value = %already set;
        
        outputStruct.s1baselineData.units = units;
        outputStruct.s1baselineData.type = 'singleValue';
        %outputStruct.baseline.value = %already set;
        
        %single epochs 
        outputStruct.s1_inwardPeak.units = units;
        outputStruct.s1_inwardPeak.type = 'byEpoch';
        outputStruct.s1_inwardPeak.value = ones(1,L) * NaN;
        
        outputStruct.s1_inwardPeak_time.units = 's';
        outputStruct.s1_inwardPeak_time.type = 'byEpoch';
        outputStruct.s1_inwardPeak_time.value = ones(1,L) * NaN;
        
        outputStruct.s2_inwardPeak.units = units;
        outputStruct.s2_inwardPeak.type = 'byEpoch';
        outputStruct.s2_inwardPeak.value = ones(1,L) * NaN;
        
        outputStruct.s2_inwardPeak_time.units = 's';
        outputStruct.s2_inwardPeak_time.type = 'byEpoch';
        outputStruct.s2_inwardPeak_time.value = ones(1,L) * NaN;
        
        outputStruct.s1_outwardPeak.units = units;
        outputStruct.s1_outwardPeak.type = 'byEpoch';
        outputStruct.s1_outwardPeak.value = ones(1,L) * NaN;
        
        outputStruct.s1_outwardPeak_time.units = 's';
        outputStruct.s1_outwardPeak_time.type = 'byEpoch';
        outputStruct.s1_outwardPeak_time.value = ones(1,L) * NaN;
        
        outputStruct.s2_outwardPeak.units = units;
        outputStruct.s2_outwardPeak.type = 'byEpoch';
        outputStruct.s2_outwardPeak.value = ones(1,L) * NaN;
        
        outputStruct.s2_outwardPeak_time.units = 's';
        outputStruct.s2_outwardPeak_time.type = 'byEpoch';
        outputStruct.s2_outwardPeak_time.value = ones(1,L) * NaN;
        
        %average traces
        outputStruct.s1_avgTraceInwardPeak.units = units;
        outputStruct.s1_avgTraceInwardPeak.type = 'singleValue';
        outputStruct.s1_avgTraceInwardPeak.value = NaN;
        
        outputStruct.s1_avgTraceOutwardPeak.units = units;
        outputStruct.s1_avgTraceOutwardPeak.type = 'singleValue';
        outputStruct.s1_avgTraceOutwardPeak.value = NaN;
        
        outputStruct.s2_avgTraceInwardPeak.units = units;
        outputStruct.s2_avgTraceInwardPeak.type = 'singleValue';
        outputStruct.s2_avgTraceInwardPeak.value = NaN;
        
        outputStruct.s2_avgTraceOutwardPeak.units = units;
        outputStruct.s2_avgTraceOutwardPeak.type = 'singleValue';
        outputStruct.s2_avgTraceOutwardPeak.value = NaN;
        
        outputStruct.s1_avgTraceInwardPeak_time.units = 's';
        outputStruct.s1_avgTraceInwardPeak_time.type = 'singleValue';
        outputStruct.s1_avgTraceInwardPeak_time.value = NaN;
        
        outputStruct.s1_avgTraceOutwardPeak_time.units = 's';
        outputStruct.s1_avgTraceOutwardPeak_time.type = 'singleValue';
        outputStruct.s1_avgTraceOutwardPeak_time.value = NaN;
        
        outputStruct.s2_avgTraceInwardPeak_time.units = 's';
        outputStruct.s2_avgTraceInwardPeak_time.type = 'singleValue';
        outputStruct.s2_avgTraceInwardPeak_time.value = NaN;
        
        outputStruct.s2_avgTraceOutwardPeak_time.units = 's';
        outputStruct.s2_avgTraceOutwardPeak_time.type = 'singleValue';
        outputStruct.s2_avgTraceOutwardPeak_time.value = NaN;
        
    end
    
    
    %stim 1 inward
    [val, pos] = min(s1_stimData);
    outputStruct.s1_inwardPeak.value(i) = -val; %flip it so it is positive
    outputStruct.s1_inwardPeak_time.value(i) = pos / sampleRate;
    
    %stim 1 outward
    [val, pos] = max(s1_stimData);
    outputStruct.s1_outwardPeak.value(i) = val;
    outputStruct.s1_outwardPeak_time.value(i) = pos / sampleRate;
    
    %stim 2 inward
    [val, pos] = min(s2_stimData);
    outputStruct.s2_inwardPeak.value(i) = -val;
    outputStruct.s2_inwardPeak_time.value(i) = pos / sampleRate;
    
    %stim 2 outward
    [val, pos] = max(s2_stimData);
    outputStruct.s2_outwardPeak.value(i) = val;
    outputStruct.s2_outwardPeak_time.value(i) = pos / sampleRate;
        
end %end of epoch loop. The stuff after this is computed on the averages instead

%baseline
outputStruct.baseline.value = mean(baselineVal);
outputStruct.s1baselineData.value = mean(s1baselineData);

%values that need to be calculated after collecting all data, get meanData
mean_stim1 = mean(Mstim1,1);
mean_stim2 = mean(Mstim2,1);

%stim 1 inward
[val, pos] = min(mean_stim1);
outputStruct.s1_avgTraceInwardPeak.value = -val;
outputStruct.s1_avgTraceInwardPeak_time.value = pos / sampleRate;

%stim 1 outward
[val, pos] = max(mean_stim1);
outputStruct.s1_avgTraceOutwardPeak.value = val;
outputStruct.s1_avgTraceOutwardPeak_time.value = pos / sampleRate;

%stim 2 inward
[val, pos] = min(mean_stim2);
outputStruct.s2_avgTraceInwardPeak.value = -val;
outputStruct.s2_avgTraceInwardPeak_time.value = pos / sampleRate;

%stim 2 outward
[val, pos] = max(mean_stim2);
outputStruct.s2_avgTraceOutwardPeak.value = val;
outputStruct.s2_avgTraceOutwardPeak_time.value = pos / sampleRate;

end


