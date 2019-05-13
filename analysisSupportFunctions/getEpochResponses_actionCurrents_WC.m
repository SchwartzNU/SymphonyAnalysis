function outputStruct = getEpochResponses_actionCurrents_WC(cellData, epochInd, varargin)
% written by Sophia for MultiPulse analyses 10/22/2018
% discontinued 4/12/19
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
    intervalEnd = (sampleEpoch.get('stim1Time') + sampleEpoch.get('stim2Time') + ip.Results.EndOffset) * 1E-3; %s
else
    intervalEnd = ip.Results.EndTime * 1E-3; %s
end
interval1End = (sampleEpoch.get('stim1Time') + ip.Results.EndOffset) * 1E-3; %s, end for stim1

sampleRate = sampleEpoch.get('sampleRate');
[data, xvals] = sampleEpoch.getData(ip.Results.DeviceName);
%set up intervals
baselineStart = xvals(1);
baselineEnd = ip.Results.BaselineTime * 1E-3;

% set up data intervals
responseIntverval = xvals >= intervalStart & xvals < intervalEnd;
response1Interval = xvals >= intervalStart & xvals < interval1End;
response2Interval = xvals >= interval1End & xvals < intervalEnd;
baselineInterval = xvals < ip.Results.BaselineTime * 1E-3;
postInterval = xvals >= intervalEnd;
responseIntervalLen = intervalEnd - intervalStart; %s
baselineIntervalLen = baselineEnd - baselineStart; %s
postIntervalLen = xvals(end) - intervalEnd; %s

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
        outputStruct.baseline.value = ones(1,L) * NaN;
        
        outputStruct.stepsStim1.units = units;
        outputStruct.stepsStim1.type = 'combinedAcrossEpochs';
        outputStruct.stepsStim1.value = ones(1,L) * NaN;
        
        outputStruct.stepsStim2.units = units;
        outputStruct.stepsStim2.type = 'combinedAcrossEpochs';
        outputStruct.stepsStim2.value = ones(1,L) * NaN;
        
        outputStruct.stim1_spikeCount.units = units;
        outputStruct.stim1_spikeCount.type = 'byEpoch';
        outputStruct.stim1_spikeCount.value = ones(1,L) * NaN;
        
        outputStruct.stim2_spikeCount.units = units;
        outputStruct.stim2_spikeCount.type = 'byEpoch';
        outputStruct.stim2_spikeCount.value = ones(1,L) * NaN;
        
        outputStruct.stim1_firstSpikeHeight.units = 'pA';
        outputStruct.stim1_firstSpikeHeight.type = 'byEpoch';
        outputStruct.stim1_firstSpikeHeight.value = ones(1,L) * NaN;
        
        outputStruct.stim2_firstSpikeHeight.units = 'pA';
        outputStruct.stim2_firstSpikeHeight.type = 'byEpoch';
        outputStruct.stim2_firstSpikeHeight.value = ones(1,L) * NaN;
        
    end
    
    % per epoch get spike count
    curEpoch = cellData.epochs(epochInd(i));
    [data, xvals, units] = curEpoch.getData(ip.Results.DeviceName);
    
    baselineData = data(baselineInterval);
    baselineVal = mean(baselineData);
    outputStruct.baseline.value(i) = baselineVal;
    
    stim1Data = data(response1Interval);
    stim2Data = data(response2Interval);
    
    outputStruct.stepsStim1.value(i) = curEpoch.get('pulse1Curr');
    outputStruct.stepsStim2.value(i) = curEpoch.get('pulse2Curr');
    
    if strcmp(curEpoch.get('wholeCellRecordingMode_Ch1'), 'Vclamp')
        % get spike times per section
        stim1SpikeTimes = getThresCross(-stim1Data, mean(-stim1Data)+500, -1);
        stim2SpikeTimes = getThresCross(-stim2Data, mean(-stim2Data)+500, -1);
        
        % get amplitude of first spike
        % C, P, T, AHP, FWHM, initSlope ] = doTimeAlign(-stim1Data, intervalStart+stim1SpikeTimes(1), curEpoch.get('sampleRate'), 181, 'VC', '' );
        outputStruct.stim1_firstSpikeHeight.value(i) = min(stim1Data);
        
        %[ C, P, T, AHP, FWHM, initSlope ] = doTimeAlign(-stim2Data, interval1End+stim2SpikeTimes(1), curEpoch.get('sampleRate'), 181, 'VC', '' );
        outputStruct.stim2_firstSpikeHeight.value(i) = min(stim2Data);
        
        
        % save data
        outputStruct.stim1_spikeCount.value(i) = length(stim1SpikeTimes);
        outputStruct.stim2_spikeCount.value(i) = length(stim2SpikeTimes);
    end
end

outputStruct.stepsStim1.value = unique(outputStruct.stepsStim1.value);
outputStruct.stepsStim2.value = unique(outputStruct.stepsStim2.value);
