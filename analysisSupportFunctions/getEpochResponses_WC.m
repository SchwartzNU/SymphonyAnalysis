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
ip.addParamValue('ZeroCrossingPeaks', [], @(x)isnumeric(x)); %parameter is a Nx2 matrix of zero crossings (in samples) and directions 

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

intervalStart = ip.Results.StartTime * 1E-3; %s
if ip.Results.EndTime == 0 %default to end at stimEnd
    intervalEnd = (sampleEpoch.get('stimTime') + ip.Results.EndOffset) * 1E-3; %s
else
    intervalEnd = ip.Results.EndTime * 1E-3; %s
end
if isnan(intervalEnd)
    intervalEnd = (sampleEpoch.get('stim1Time') + sampleEpoch.get('stim2Time') + ip.Results.EndOffset) * 1E-3; %s
end

sampleRate = sampleEpoch.get('sampleRate');
[data, xvals] = sampleEpoch.getData(ip.Results.DeviceName);
%set upintervals
baselineStart = xvals(1);
baselineEnd = ip.Results.BaselineTime * 1E-3;

responseInterval = xvals >= intervalStart & xvals < intervalEnd;
transientInterval = xvals >= intervalStart & xvals < intervalStart + 0.1;
sustainedInterval = xvals >= intervalEnd - 0.1 & xvals < intervalEnd;
baselineInterval = xvals < ip.Results.BaselineTime * 1E-3;
postInterval = xvals >= intervalEnd;
responseIntervalLen = intervalEnd - intervalStart; %s
baselineIntervalLen = baselineEnd - baselineStart; %s
postIntervalLen = xvals(end) - intervalEnd; %s

Mstim = zeros(L, sum(responseInterval)); %full data matrix, baseline subtracted on each epoch
Mtrans = zeros(L, sum(transientInterval)); %transient data matrix, baseline subtracted on each epoch
Msus = zeros(L, sum(sustainedInterval)); %sustained data matrix, baseline subtracted on each epoch
Mpost = zeros(L, sum(postInterval)); %full data matrix, baseline subtracted on each epoch
MstimToEnd = zeros(L, sum(responseInterval) + sum(postInterval));
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
    stimData = data(responseInterval);
    transData = data(transientInterval);
    susData = data(sustainedInterval);
    postData = data(postInterval);    
    
    if responseIntervalLen >= 0.2
        stimData200 = data(xvals > 0 & xvals <= 0.2);
    else
        stimData200 = [];
    end
    
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
    if responseIntervalLen >= 1
        stimData200to1000 = data(xvals > 0.2 & xvals <= 1);
    else
        stimData200to1000 = [];
    end
    
    if responseIntervalLen >= 1
        stimData1000 = data(xvals > 0 & xvals <= 1);
    else
        stimData1000 = [];
    end
    if responseIntervalLen >= 1
        stimData_next1000 = data(xvals > 1 & xvals < 2);
    else
        stimData_next1000 = [];
    end
    
    % moving bar data segments
    centerTime = (intervalEnd - intervalStart)/2 + .2;
    dataBeforeCenter = data(xvals > (centerTime - 1) & xvals < centerTime);
    dataAfterCenter = data(xvals > centerTime & xvals < (centerTime + 1));
    
    Mstim(i,:) = stimData;   
    Mtrans(i,:) = transData;
    Msus(i,:) = susData;
    Mpost(i,:) = postData;
    stimToEndData = [stimData postData];
    MstimToEnd(i,:) = stimToEndData;

    
    if i==1 %some stuff we only need to do once: units and types for each output
        outputStruct.baseline.units = units;
        outputStruct.baseline.type = 'singleValue';
        %outputStruct.baseline.value = %already set;
        
        outputStruct.stimToEnd_peak.units = units;
        outputStruct.stimToEnd_peak.type = 'byEpoch';
        outputStruct.stimToEnd_peak.value = ones(1,L) * NaN;
        
        outputStruct.stimToEnd_avgTracePeak.units = units;
        outputStruct.stimToEnd_avgTracePeak.type = 'singleValue';
        outputStruct.stimToEnd_avgTracePeak.value = NaN;
        
        outputStruct.stimToEnd_respIntervalT25.units = 's';
        outputStruct.stimToEnd_respIntervalT25.type = 'singleValue';
        outputStruct.stimToEnd_respIntervalT25.value = 0;
        
        outputStruct.stimToEnd_respIntervalT50.units = 's';         %Adam 2/19/16
        outputStruct.stimToEnd_respIntervalT50.type = 'singleValue';
        outputStruct.stimToEnd_respIntervalT50.value = 0;
        
        outputStruct.stimToEnd_chargeT25.units = 'pC';
        outputStruct.stimToEnd_chargeT25.type = 'byEpoch';
        outputStruct.stimToEnd_chargeT25.value = ones(1,L) * NaN;
        
        outputStruct.stimToEnd_avgTrace_latencyToT50.units = 's';
        outputStruct.stimToEnd_avgTrace_latencyToT50.type = 'singleValue';
        outputStruct.stimToEnd_avgTrace_latencyToT50.value = NaN;
        
        outputStruct.stimToEnd_avgTrace_latencyToT25.units = 's';
        outputStruct.stimToEnd_avgTrace_latencyToT25.type = 'singleValue';
        outputStruct.stimToEnd_avgTrace_latencyToT25.value = NaN;
        
        outputStruct.stimToEnd_latencyToPeak.units = 's';
        outputStruct.stimToEnd_latencyToPeak.type = 'byEpoch';
        outputStruct.stimToEnd_latencyToPeak.value = NaN;
        
        outputStruct.stimToEnd_avgTrace_latencyToPeak.units = 's';
        outputStruct.stimToEnd_avgTrace_latencyToPeak.type = 'singleValue';
        outputStruct.stimToEnd_avgTrace_latencyToPeak.value = NaN;
        
        outputStruct.stimInterval_charge.units = 'pC';
        outputStruct.stimInterval_charge.type = 'byEpoch';
        outputStruct.stimInterval_charge.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_peak.units = units;
        outputStruct.ONSET_peak.type = 'byEpoch';
        outputStruct.ONSET_peak.value = ones(1,L) * NaN;
        
        outputStruct.OFFSET_peak.units = units;
        outputStruct.OFFSET_peak.type = 'byEpoch';
        outputStruct.OFFSET_peak.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_peak400ms.units = units;
        outputStruct.ONSET_peak400ms.type = 'byEpoch';
        outputStruct.ONSET_peak400ms.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_peak1000ms.units = units;
        outputStruct.ONSET_peak1000ms.type = 'byEpoch';
        outputStruct.ONSET_peak1000ms.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_peak_next1000ms.units = units;
        outputStruct.ONSET_peak_next1000ms.type = 'byEpoch';
        outputStruct.ONSET_peak_next1000ms.value = ones(1,L) * NaN;
        
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
        
        outputStruct.ONSET_charge1000ms.units = 'pC';
        outputStruct.ONSET_charge1000ms.type = 'byEpoch';
        outputStruct.ONSET_charge1000ms.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_charge_next1000ms.units = 'pC';
        outputStruct.ONSET_charge_next1000ms.type = 'byEpoch';
        outputStruct.ONSET_charge_next1000ms.value = ones(1,L) * NaN;
        
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
                
        %Amurta 12/15/15
        outputStruct.ONSETtransPeak.units = units;
        outputStruct.ONSETtransPeak.type = 'byEpoch';
        outputStruct.ONSETtransPeak.value = ones(1,L) * NaN;
        
        %Amurta 12/15/15
        outputStruct.ONSETsusPeak.units = units;
        outputStruct.ONSETsusPeak.type = 'byEpoch';
        outputStruct.ONSETsusPeak.value = ones(1,L) * NaN;
        
        % Sam 7/31/17
        outputStruct.charge_mbLeading.units = 'pC';
        outputStruct.charge_mbLeading.type = 'byEpoch';
        outputStruct.charge_mbLeading.value = ones(1,L) * NaN;
        
        % Sam 7/31/17
        outputStruct.charge_mbTrailing.units = 'pC';
        outputStruct.charge_mbTrailing.type = 'byEpoch';
        outputStruct.charge_mbTrailing.value = ones(1,L) * NaN;
        
       % Sam 8/1/17
        outputStruct.peak_mbLeading.units = 'pC';
        outputStruct.peak_mbLeading.type = 'byEpoch';
        outputStruct.peak_mbLeading.value = ones(1,L) * NaN;
        
        % Sam 8/1/17
        outputStruct.peak_mbTrailing.units = 'pC';
        outputStruct.peak_mbTrailing.type = 'byEpoch';
        outputStruct.peak_mbTrailing.value = ones(1,L) * NaN;        
    end
    
    %stimToEnd
    if abs(max(stimData)) > abs(min(stimData)) %outward current larger
        [outputStruct.stimToEnd_peak.value(i), pos] = max(stimToEndData);
        outputStruct.stimToEnd_latencyToPeak.value(i) = pos / sampleRate;
    else %inward current larger
        [outputStruct.stimToEnd_peak.value(i), pos] = min(stimToEndData);
        outputStruct.stimToEnd_latencyToPeak.value(i) = pos / sampleRate;
    end
    
    %ONSET
    if abs(max(stimData)) > abs(min(stimData)) %outward current larger
        [outputStruct.ONSET_peak.value(i), pos] = max(stimData);
        outputStruct.ONSET_latencyToPeak.value(i) = pos / sampleRate;
    else %inward current larger
        [outputStruct.ONSET_peak.value(i), pos] = min(stimData);
        outputStruct.ONSET_latencyToPeak.value(i) = pos / sampleRate;
    end
    outputStruct.stimInterval_charge.value(i) = sum(stimData) * responseIntervalLen / sampleRate; %pC
    
    %ONSET
    if ~isempty(transData)
        if abs(max(transData)) > abs(min(transData)) %outward current larger
            outputStruct.ONSETtransPeak.value(i) = max(transData);
        else %inward current larger
            outputStruct.ONSETtransPeak.value(i) = min(transData);
        end
    end
    
    %ONSET
    if ~isempty(susData)
        if abs(max(susData)) > abs(min(susData)) %outward current larger
            outputStruct.ONSETsusPeak.value(i) = max(susData);
        else %inward current larger
            outputStruct.ONSETsusPeak.value(i) = min(susData);
        end
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
    
    %ONSET
    if ~isempty(stimData1000)
        if abs(max(stimData1000)) > abs(min(stimData1000)) %outward current larger
            outputStruct.ONSET_peak1000ms.value(i) = max(stimData1000);
        else %inward current larger
            outputStruct.ONSET_peak1000ms.value(i) = min(stimData1000);
        end
        outputStruct.ONSET_charge1000ms.value(i) = sum(stimData1000) * 1 / sampleRate;
    end
    
    %ONSET
    if ~isempty(stimData_next1000)
        if abs(max(stimData_next1000)) > abs(min(stimData_next1000)) %outward current larger
            outputStruct.ONSET_peak_next1000ms.value(i) = max(stimData_next1000);
        else %inward current larger
            outputStruct.ONSET_peak_next1000ms.value(i) = min(stimData_next1000);
        end
        outputStruct.ONSET_charge_next1000ms.value(i) = sum(stimData_next1000) * 1 / sampleRate;
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
    
    % moving bar leading and trailing edges  
    if ~isempty(dataBeforeCenter)
        if abs(max(dataBeforeCenter)) > abs(min(dataBeforeCenter)) %outward current larger
            outputStruct.peak_mbLeading.value(i) = max(dataBeforeCenter);
        else %inward current larger
            outputStruct.peak_mbLeading.value(i) = min(dataBeforeCenter);
        end
        outputStruct.charge_mbLeading.value(i) = sum(dataBeforeCenter) * 1.0 / sampleRate;
    end    
    
    if ~isempty(dataAfterCenter)
        if abs(max(dataAfterCenter)) > abs(min(dataAfterCenter)) %outward current larger
            outputStruct.peak_mbTrailing.value(i) = max(dataAfterCenter);
        else %inward current larger
            outputStruct.peak_mbTrailing.value(i) = min(dataAfterCenter);
        end
        outputStruct.charge_mbTrailing.value(i) = sum(dataAfterCenter) * 1.0 / sampleRate;
    end        
    
end

%baseline
outputStruct.baseline.value = mean(baselineVal);

if ~isempty(ip.Results.ZeroCrossingPeaks)
    zeroCrossings = ip.Results.ZeroCrossingPeaks(1,:);
    directions = ip.Results.ZeroCrossingPeaks(2,:);
    Npeaks = length(zeroCrossings)-1;
    dataMean = mean(data, 1);
    
    %keyboard;
    %start from the end and count
    for i=1:Npeaks
        varName = ['peak' num2str(i) '_avgTracePeak'];
        outputStruct.(varName).units = units;
        outputStruct.(varName).type = 'singleValue';
        if directions(i) == -1 %negative peak
            [peakVal, ind] = min(dataMean(zeroCrossings(i):zeroCrossings(i+1)));
        else
            [peakVal, ind] = max(dataMean(zeroCrossings(i):zeroCrossings(i+1)));
        end
        peakTime = xvals(ind(1) + zeroCrossings(i));
        outputStruct.(varName).value = peakVal;
        
        varName = ['peak' num2str(i) '_avgTraceLatencyToPeak'];
        outputStruct.(varName).units = 's';
        outputStruct.(varName).type = 'singleValue';
        outputStruct.(varName).value = peakTime;
    end
end

%values that need to be calculated after collecting all data
%stimToEnd
meanTrace_stimToEnd = [mean(Mstim, 1), mean(Mpost, 1)];
if abs(max(meanTrace_stimToEnd)) > abs(min(meanTrace_stimToEnd)) %outward current larger
    [outputStruct.stimToEnd_avgTracePeak.value, pos] = max(meanTrace_stimToEnd);
    outputStruct.stimToEnd_avgTrace_latencyToPeak.value = pos / sampleRate;
    thresDir = 1;
else %inward current larger
    [outputStruct.stimToEnd_avgTracePeak.value, pos] = min(meanTrace_stimToEnd);
    outputStruct.stimToEnd_avgTrace_latencyToPeak.value = pos / sampleRate;
    thresDir = -1;
end

%thresholds
maxVal = outputStruct.stimToEnd_avgTracePeak.value;
T25_up = getThresCross(meanTrace_stimToEnd, 0.25*maxVal, thresDir);
T25_down = getThresCross(meanTrace_stimToEnd, 0.25*maxVal, -thresDir);
T50_up = getThresCross(meanTrace_stimToEnd, 0.5*maxVal, thresDir);
T50_down = getThresCross(meanTrace_stimToEnd, 0.5*maxVal, -thresDir);
if ~isempty(T25_up) && ~isempty(T25_down)
    %     timeDiff_up = T25_up - pos;
    %     timeDiff_up_abs = abs(timeDiff_up);
    %     timeDiff_down = T25_down - pos;
    %     timeDiff_down_abs = abs(timeDiff_down);
    %     [~, prePos] = min(timeDiff_up_abs(timeDiff_up<0)); MISTAKE, the vector inside "min" is shortened by the indexing
    %     [~, postPos] = min(timeDiff_down_abs(timeDiff_down>0));
    
    % % % Corrected by Adam 2/2016
    timeDiff_up = T25_up - pos;
    timeDiff_down = T25_down - pos;
    T25_up = T25_up(timeDiff_up<0);
    T25_down = T25_down(timeDiff_down>0);
    [~, prePos] = max(T25_up);
    [~, postPos] = min(T25_down);
    % % % % % % % % Hack to avoind including OFF response! Adam
    if T25_up(prePos) > 1.1*sampleRate
        T25_up(prePos) = 1.1*sampleRate;
    end;
    if T25_down(postPos) > 1.1*sampleRate
        T25_down(postPos) = 1.1*sampleRate;
    end;
    % % % % % % % %
    
    if ~isempty(prePos) && ~isempty(postPos)
        outputStruct.stimToEnd_avgTrace_latencyToT25.value = T25_up(prePos) / sampleRate;
        
        outputStruct.stimToEnd_respIntervalT25.value = (T25_down(postPos) - T25_up(prePos)) / sampleRate;
        for i=1:L
            outputStruct.stimToEnd_chargeT25.value(i) = mean(MstimToEnd(i,T25_up(prePos):T25_down(postPos))) * outputStruct.stimToEnd_respIntervalT25.value;
        end
    end
end
if ~isempty(T50_up)
    timeDiff = T50_up - pos;
    timeDiff_abs = abs(timeDiff);
    [~, prePos] = min(timeDiff_abs(timeDiff<0));
    if ~isempty(prePos)
        outputStruct.stimToEnd_avgTrace_latencyToT50.value = T50_up(prePos) / sampleRate;
    end
    if ~isempty(T50_down)
        timeDiff_up = T50_up - pos;
        timeDiff_down = T50_down - pos;
        T50_up = T50_up(timeDiff_up<0);
        T50_down = T50_down(timeDiff_down>0);
        [~, prePos] = max(T50_up);
        [~, postPos] = min(T50_down);
        
        if ~isempty(prePos) && ~isempty(postPos)
            outputStruct.stimToEnd_respIntervalT50.value = (T50_down(postPos) - T50_up(prePos)) / sampleRate;
        end
    end
end

%ONSET
meanTrace_stim = mean(Mstim, 1);
meanTrace_stimToEnd = [mean(Mstim, 1), mean(Mpost, 1)];
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
T25_up = getThresCross(meanTrace_stimToEnd, 0.25*maxVal, thresDir);
T25_down = getThresCross(meanTrace_stimToEnd, 0.25*maxVal, -thresDir);
T50_up = getThresCross(meanTrace_stimToEnd, 0.5*maxVal, thresDir);
% T25_up = getThresCross(meanTrace_stim, 0.25*maxVal, thresDir);     %PROBLEM: Doesn't take care of trace still up at stim offset.
% T25_down = getThresCross(meanTrace_stim, 0.25*maxVal, -thresDir);
% T50 = getThresCross(meanTrace_stim, 0.5*maxVal, thresDir);
if ~isempty(T25_up) && ~isempty(T25_down)
%     timeDiff_up = T25_up - pos;
%     timeDiff_up_abs = abs(timeDiff_up);
%     timeDiff_down = T25_down - pos;
%     timeDiff_down_abs = abs(timeDiff_down);
%     [~, prePos] = min(timeDiff_up_abs(timeDiff_up<0));
%     [~, postPos] = min(timeDiff_down_abs(timeDiff_down>0)); MISTAKE

% % % Corrected by Adam 2/2016
timeDiff_up = T25_up - pos;
timeDiff_down = T25_down - pos;
T25_up = T25_up(timeDiff_up<0);
T25_down = T25_down(timeDiff_down>0);
[~, prePos] = max(T25_up);
[~, postPos] = min(T25_down);

    if ~isempty(prePos) && ~isempty(postPos)
        outputStruct.ONSET_respIntervalT25.value = (T25_down(postPos) - T25_up(prePos)) / sampleRate;
        for i=1:L
            outputStruct.ONSET_chargeT25.value(i) = mean(MstimToEnd(i,T25_up(prePos):T25_down(postPos))) * outputStruct.ONSET_respIntervalT25.value;
        end
    end
end
if ~isempty(T50_up)
    timeDiff = T50_up - pos;
    timeDiff_abs = abs(timeDiff);
    [~, prePos] = min(timeDiff_abs(timeDiff<0));
    if ~isempty(prePos)
        outputStruct.ONSET_avgTrace_latencyToT50.value = T50_up(prePos) / sampleRate;
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
T50_up = getThresCross(meanTrace_post, 0.5*maxVal, thresDir);
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
            outputStruct.OFFSET_chargeT25.value(i) = mean(Mpost(i,T25_up(prePos):T25_down(postPos))) * outputStruct.OFFSET_respIntervalT25.value;
        end
    end
end
if ~isempty(T50_up)
    timeDiff = T50_up - pos;
    timeDiff_abs = abs(timeDiff);
    [~, prePos] = min(timeDiff_abs(timeDiff<0));
    if ~isempty(prePos)
        outputStruct.OFFSET_avgTrace_latencyToT50.value = T50_up(prePos) / sampleRate;
    end
end


end


