function outputStruct = getEpochResponses_WC(cellData, epochInd, varargin)
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
%set upintervals
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
    
    if responseIntervalLen >= 0.4
        stimData400 = data(xvals > 0 & xvals <= 0.4);
    else
        stimData400 = [];
    end
    if postIntervalLen > 0.4
        postData400 = data(xvals > intervalEnd & xvals < intervalEnd + 0.4);
    else
        postData400 = [];
    end
    
    Mstim(i,:) = stimData;
    Mpost(i,:) = postData;
    
    if i==1 %some stuff we only need to do once: units and types for each output
        outputStruct.baseline.units = units;
        outputStruct.baseline.type = 'singleValue';
        %outputStruct.baseline.value = %already set;
        
        outputStruct.ONSET_peak.units = units;
        outputStruct.ONSET_peak.type = 'byEpoch';
        outputStruct.ONSET_peak.value = ones(1,L) * NaN;
        
        outputStruct.OFFSET_peak.units = units;
        outputStruct.OFFSET_peak.type = 'byEpoch';
        outputStruct.OFFSET_peak.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_peak400ms.units = units;
        outputStruct.ONSET_peak400ms.type = 'byEpoch';
        outputStruct.ONSET_peak400ms.value = ones(1,L) * NaN;
        
        outputStruct.OFFSET_peak400ms.units = units;
        outputStruct.OFFSET_peak400ms.type = 'byEpoch';
        outputStruct.OFFSET_peak400ms.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_avgTracePeak.units = units;
        outputStruct.ONSET_avgTracePeak.type = 'singleValue';
        outputStruct.ONSET_avgTracePeak.value = NaN;
        
        outputStruct.OFFSET_avgTracePeak.units = units;
        outputStruct.OFFSET_avgTracePeak.type = 'singleValue';
        outputStruct.OFFSET_avgTracePeak.value = NaN;
        
        outputStruct.ONSET_charge400ms.units = 'pC';
        outputStruct.ONSET_charge400ms.type = 'byEpoch';
        outputStruct.ONSET_charge400ms.value = ones(1,L) * NaN;
        
        outputStruct.OFFSET_charge400ms.units = 'pC';
        outputStruct.OFFSET_charge400ms.type = 'byEpoch';
        outputStruct.OFFSET_charge400ms.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_respIntervalT25.units = 's';
        outputStruct.ONSET_respIntervalT25.type = 'singleValue';
        outputStruct.ONSET_respIntervalT25.value = 0;
        
        outputStruct.OFFSET_respIntervalT25.units = 's';
        outputStruct.OFFSET_respIntervalT25.type = 'singleValue';
        outputStruct.OFFSET_respIntervalT25.value = 0;
        
        outputStruct.ONSET_chargeT25.units = 'pC';
        outputStruct.ONSET_chargeT25.type = 'byEpoch';
        outputStruct.ONSET_chargeT25.value = ones(1,L) * NaN;
        
        outputStruct.OFFSET_chargeT25.units = 'pC';
        outputStruct.OFFSET_chargeT25.type = 'byEpoch';
        outputStruct.OFFSET_chargeT25.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_latencyToPeak.units = 's';
        outputStruct.ONSET_latencyToPeak.type = 'byEpoch';
        outputStruct.ONSET_latencyToPeak.value = NaN;
        
        outputStruct.OFFSET_latencyToPeak.units = 's';
        outputStruct.OFFSET_latencyToPeak.type = 'byEpoch';
        outputStruct.OFFSET_latencyToPeak.value = NaN;
        
        outputStruct.ONSET_avgTrace_latencyToPeak.units = 's';
        outputStruct.ONSET_avgTrace_latencyToPeak.type = 'singleValue';
        outputStruct.ONSET_avgTrace_latencyToPeak.value = NaN;
        
        outputStruct.OFFSET_avgTrace_latencyToPeak.units = 's';
        outputStruct.OFFSET_avgTrace_latencyToPeak.type = 'singleValue';
        outputStruct.OFFSET_avgTrace_latencyToPeak.value = NaN;
        
        outputStruct.ONSET_avgTrace_latencyToT50.units = 's';
        outputStruct.ONSET_avgTrace_latencyToT50.type = 'singleValue';
        outputStruct.ONSET_avgTrace_latencyToT50.value = NaN;
        
        outputStruct.OFFSET_avgTrace_latencyToT50.units = 's';
        outputStruct.OFFSET_avgTrace_latencyToT50.type = 'singleValue';
        outputStruct.OFFSET_avgTrace_latencyToT50.value = NaN;
    end
    
    %ONSET
    if abs(max(stimData)) > abs(min(stimData)) %outward current larger
        [outputStruct.ONSET_peak.value(i), pos] = max(stimData);
        outputStruct.ONSET_latencyToPeak.value(i) = pos / sampleRate;
    else %inward current larger
        [outputStruct.ONSET_peak.value(i), pos] = min(stimData);
        outputStruct.ONSET_latencyToPeak.value(i) = pos / sampleRate;
    end
    
    %ONSET
    if ~isempty(stimData400)
        if abs(max(stimData400)) > abs(min(stimData400)) %outward current larger
            outputStruct.ONSET_peak400ms.value(i) = max(stimData400);
        else %inward current larger
            outputStruct.ONSET_peak400ms.value(i) = min(stimData400);
        end
        outputStruct.ONSET_charge400ms.value(i) = sum(stimData400) * 0.4 / sampleRate;
    end
    
    %OFFSET
    if abs(max(postData)) > abs(min(postData)) %outward current larger
        [outputStruct.OFFSET_peak.value(i), pos] = max(postData);
        outputStruct.OFFSET_latencyToPeak.value(i) = pos / sampleRate;
    else %inward current larger
        [outputStruct.OFFSET_peak.value(i), pos] = min(postData);
        outputStruct.OFFSET_latencyToPeak.value(i) = pos / sampleRate;
    end
    
    %OFFSET
    if ~isempty(postData400)
        if abs(max(postData400)) > abs(min(postData400)) %outward current larger
            outputStruct.OFFSET_peak400ms.value(i) = max(postData400);
        else %inward current larger
            outputStruct.OFFSET_peak400ms.value(i) = min(postData400);
        end
        outputStruct.OFFSET_charge400ms.value(i) = sum(postData400) * 0.4 / sampleRate;
    end
    
end

%baseline 
outputStruct.baseline.value = mean(baselineVal);

%values that need to be calculated after collecting all data
%ONSET
meanTrace_stim = mean(Mstim, 1);
if abs(max(meanTrace_stim)) > abs(min(meanTrace_stim)) %outward current larger
    [outputStruct.ONSET_avgTracePeak.value, pos] = max(meanTrace_stim);
    outputStruct.ONSET_avgTrace_latencyToPeak.value = pos / sampleRate;
    thresDir = 1;
else %inward current larger
    [outputStruct.ONSET_avgTracePeak.value, pos] = min(meanTrace_stim);
    outputStruct.ONSET_avgTrace_latencyToPeak.value = pos / sampleRate; 
    thresDir = -1;
end
%thresholds
maxVal = outputStruct.ONSET_avgTracePeak.value;
T25_up = getThresCross(meanTrace_stim, 0.25*maxVal, thresDir);
T25_down = getThresCross(meanTrace_stim, 0.25*maxVal, -thresDir);
T50 = getThresCross(meanTrace_stim, 0.5*maxVal, thresDir);
if ~isempty(T25_up) && ~isempty(T25_down)
    timeDiff_up = T25_up - pos;
    timeDiff_up_abs = abs(timeDiff_up);
    timeDiff_down = T25_down - pos;
    timeDiff_down_abs = abs(timeDiff_down);
    [~, prePos] = min(timeDiff_up_abs(timeDiff_up<0));
    [~, postPos] = min(timeDiff_down_abs(timeDiff_down>0));
    if ~isempty(prePos) && ~isempty(postPos)
        outputStruct.ONSET_respIntervalT25.value = (T25_down(postPos) - T25_up(prePos)) / sampleRate;
        for i=1:L
            outputStruct.ONSET_chargeT25.value(i) = sum(Mstim(i,T25_up(prePos):T25_down(postPos))) * outputStruct.ONSET_respIntervalT25.value;
        end
    end
end
if ~isempty(T50)
    timeDiff = T50 - pos;
    timeDiff_abs = abs(timeDiff);
    [~, prePos] = min(timeDiff_abs(timeDiff<0));
    if ~isempty(prePos)
        outputStruct.ONSET_avgTrace_latencyToT50.value = T50(prePos) / sampleRate;
    end
end


%OFFSET
meanTrace_post = mean(Mpost, 1);
if abs(max(meanTrace_post)) > abs(min(meanTrace_post)) %outward current larger
    [outputStruct.OFFSET_avgTracePeak.value, pos] = max(meanTrace_post);
    outputStruct.OFFSET_avgTrace_latencyToPeak.value = pos / sampleRate;
    thresDir = 1;
else %inward current larger
    [outputStruct.OFFSET_avgTracePeak.value, pos] = min(meanTrace_post);
    outputStruct.OFFSET_avgTrace_latencyToPeak.value = pos / sampleRate;
    thresDir = -1;
end
%thresholds
maxVal = outputStruct.OFFSET_avgTracePeak.value;
T25_up = getThresCross(meanTrace_post, 0.25*maxVal, thresDir);
T25_down = getThresCross(meanTrace_post, 0.25*maxVal, -thresDir);
T50 = getThresCross(meanTrace_post, 0.5*maxVal, thresDir);
if ~isempty(T25_up) && ~isempty(T25_down)
    timeDiff_up = T25_up - pos;
    timeDiff_up_abs = abs(timeDiff_up);
    timeDiff_down = T25_down - pos;
    timeDiff_down_abs = abs(timeDiff_down);
    [~, prePos] = min(timeDiff_up_abs(timeDiff_up<0));
    [~, postPos] = min(timeDiff_down_abs(timeDiff_down>0));
    if ~isempty(prePos) && ~isempty(postPos)
        outputStruct.OFFSET_respIntervalT25.value = (T25_down(postPos) - T25_up(prePos)) / sampleRate;
        for i=1:L
            outputStruct.OFFSET_chargeT25.value(i) = sum(Mpost(i,T25_up(prePos):T25_down(postPos))) * outputStruct.OFFSET_respIntervalT25.value;
        end
    end
end
if ~isempty(T50)
    timeDiff = T50 - pos;
    timeDiff_abs = abs(timeDiff);
    [~, prePos] = min(timeDiff_abs(timeDiff<0));
    if ~isempty(prePos)
        outputStruct.OFFSET_avgTrace_latencyToT50.value = T50(prePos) / sampleRate;
    end
end


end


