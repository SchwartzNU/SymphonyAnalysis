function outputStruct = getEpochResponses_WC_MP_IC(cellData, epochInd, varargin)
% Written by Sophia for WC IC recordings of spikes
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
stim1Interval = xvals > stim1Start & xvals < stim2Start;
stim2Interval = xvals > stim2Start & xvals < stim2End;

%currently not using these transient intervals, but we could
stim1TransInterval = xvals > stim1Start & xvals < stim1Start + .05; % 50 ms at start
stim2TransInterval = xvals > stim2Start & xvals < stim2Start + .05; % 50 ms at start

%baseline at end of step
stim1BaseInterval = xvals > stim2Start - .1 & xvals < stim2Start; % 100 ms before end of stim1
stim2BaseInterval = xvals > stim2End - .1 & xvals < stim2End; % 100 ms before end of stim2

Mstim1 = zeros(L, sum(stim1Interval)); %full data matrix, baseline subtracted on each epoch
Mstim2 = zeros(L, sum(stim2Interval)); %full data matrix, baseline subtracted on each epoch
Mstim1trans = zeros(L, sum(stim1TransInterval)); %full data matrix, baseline subtracted on each epoch
Mstim2trans = zeros(L, sum(stim2TransInterval)); %full data matrix, baseline subtracted on each epoch

baselineVal = zeros(1,L); %baseline in prepoints
stim1baselineVal = zeros(1,L); %steady state at the end of stim1
stim2baselineVal = zeros(1,L); %steady state at the end of stim2

R = ones(1, L)*NaN;
Vm = ones(3, L)*NaN;
for i=1:L %loops over epochs
    curEpoch = cellData.epochs(epochInd(i));
    %get data
    [data, xvals, units] = curEpoch.getData(ip.Results.DeviceName);
    
    baselineData = data(baselineInterval);
    baselineVal(i) = mean(baselineData);
    
    s1baselineData = data(stim1BaseInterval);
    stim1baselineVal(i) = mean(s1baselineData);
    
    s2baselineData = data(stim2BaseInterval);
    stim2baselineVal(i) = mean(s2baselineData);
    
    %baseline subtraction
    s1_stimData = data(stim1Interval) - stim1baselineVal(i);
    Mstim1(i,:) = s1_stimData;
    s1_stimData_trans = data(stim1TransInterval) - stim1baselineVal(i);
    Mstim1trans(i,:) = s1_stimData_trans;
    
    s2_stimData = data(stim2Interval) - stim2baselineVal(i);
    Mstim2(i,:) = s2_stimData;
    s2_stimData_trans = data(stim2TransInterval) - stim2baselineVal(i);
    Mstim2trans(i,:) = s2_stimData_trans;
    
    if i==1 %some stuff we only need to do once: units and types for each output
        outputStruct.baseline.units = units;
        outputStruct.baseline.type = 'singleValue';
        %outputStruct.baseline.value = %already set;
        
        outputStruct.resistance.units = 'Mohms';
        outputStruct.resistance.type = 'singleValue';
        outputStruct.resistance.value = NaN;
        
        outputStruct.resistanceSD.units = 'Mohms';
        outputStruct.resistanceSD.type = 'singleValue';
        outputStruct.resistanceSD.value = NaN;
        
        outputStruct.s1baselineData.units = units;
        outputStruct.s1baselineData.type = 'singleValue';
        %outputStruct.baseline.value = %already set;
        
        outputStruct.s1_steps.units = units;
        outputStruct.s1_steps.type = 'combinedAcrossEpochs';
        outputStruct.s1_steps.value = ones(1,L) * NaN;
        
        outputStruct.s2_steps.units = units;
        outputStruct.s2_steps.type = 'combinedAcrossEpochs';
        outputStruct.s2_steps.value = ones(1,L) * NaN;
        
        outputStruct.s1_spikeCount.units = units;
        outputStruct.s1_spikeCount.type = 'byEpoch';
        outputStruct.s1_spikeCount.value = ones(1,L) * NaN;
        
        outputStruct.s2_spikeCount.units = units;
        outputStruct.s2_spikeCount.type = 'byEpoch';
        outputStruct.s2_spikeCount.value = ones(1,L) * NaN;
        
        % Vm stuff added 6/18/2019
        outputStruct.Vm_preTime.units = units;
        outputStruct.Vm_preTime.type = 'combinedAcrossEpochs';
        outputStruct.Vm_preTime.value = NaN;
        
        outputStruct.Vm_stim1Time.units = units;
        outputStruct.Vm_stim1Time.type = 'combinedAcrossEpochs';
        outputStruct.Vm_stim1Time.value = NaN;
        
        outputStruct.Vm_stim2Time.units = units;
        outputStruct.Vm_stim2Time.type = 'combinedAcrossEpochs';
        outputStruct.Vm_stim2Time.value = NaN;
        
    end
    
    % added from Sophia MP getEpochResponsese
    step1 = curEpoch.get('pulse1Curr'); step2 = curEpoch.get('pulse2Curr');
    outputStruct.s1_steps.value(i) = step1;
    outputStruct.s2_steps.value(i) = step2;
    spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName); % copied from the gER_CA
    spikeTimes = (spikeTimes / sampleRate) - (curEpoch.get('preTime')/1000);
    stim1Spikes = spikeTimes > stim1Start & spikeTimes < stim2Start;
    stim2Spikes = spikeTimes > stim2Start & spikeTimes < stim2End;
    outputStruct.s1_spikeCount.value(i) = sum(stim1Spikes);
    outputStruct.s2_spikeCount.value(i) = sum(stim2Spikes);
    
    % calculate resistance 
    d_filt = movmedian(data, 101*sampleRate/10000);
    preBase = mean(d_filt(baselineInterval));
    stim1Base = mean(d_filt(xvals > stim1Start+0.05 & xvals < stim2Start));
    stim2Base = mean(d_filt(xvals > stim2Start+0.1 & xvals < stim2End));
    if step1 ~= 0
        R(i) = ((stim1Base - preBase)/step1)*(1E3);
    end
    Vm(1, i) = preBase;
    Vm(2, i) = stim1Base;
    Vm(3, i) = stim2Base;
    
    
end %end of epoch loop. The stuff after this is computed on the averages instead

%baseline
outputStruct.baseline.value = mean(baselineVal);
outputStruct.s1baselineData.value = mean(s1baselineData);

outputStruct.resistance.value = nanmean(R);
outputStruct.resistanceSD.value = nanstd(R);

% voltage
outputStruct.Vm_preTime.value = nanmean(Vm(1, :));
outputStruct.Vm_stim1Time.value = nanmean(Vm(2, :));
outputStruct.Vm_stim2Time.value = nanmean(Vm(3, :));

% collect all of the steps
outputStruct.s1_steps.value = unique(outputStruct.s1_steps.value);
outputStruct.s2_steps.value = unique(outputStruct.s2_steps.value);

end


