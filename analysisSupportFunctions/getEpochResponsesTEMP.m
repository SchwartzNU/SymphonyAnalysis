function outputStruct = getEpochResponsesTEMP(cellData, epochInd, varargin)
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

%spike amplitude stuff here - TODO: figure out how to get amplitude profile
[spikeAmps_all, ~, averageWaveform] = getSpikeAmplitudesForEpochs(cellData, epochInd, ip.Results.DeviceName);
outputStruct.averageSpikeWaveform.value = averageWaveform;

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
    
    %only cell-attached in this version: TODO: change name of function to
    %reflect this
    
    %get spike times (in units of seconds from startTime
    spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName);
    spikeTimes = spikeTimes - stimStart;
    spikeTimes = spikeTimes / sampleRate;
    
    %TEMP HACK: This is to remove crazy refractory preiod violations from the spike detector
    if  length(spikeTimes) >= 2
        ISItest = diff(spikeTimes);
        spikeAmps_all{i} = spikeAmps_all{i}([(ISItest > 0.0015) true]);
        spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
    end;
    fullISI = [fullISI, cumsum(diff(spikeTimes))];
    %fraction difference of spikeAmps
    spikeAmps_all{i} = spikeAmps_all{i} / max(spikeAmps_all{i});
    fullSpikeAmpDiff = [fullSpikeAmpDiff; cumsum(diff(spikeAmps_all{i}))];
    % % %
    
    %get baselineISIs
    baselineSpikeTimes = spikeTimes(spikeTimes < baselineEnd);
    baselineInterSpTimes = diff(baselineSpikeTimes);
    outputStruct.baselineRate.value(i) = length(baselineSpikeTimes) / baselineIntervalLen;
    
    blISI{i} = baselineInterSpTimes; %ISI to next spike
    blISI2{i} = baselineInterSpTimes(1:end-1)+baselineInterSpTimes(2:end); %ISI to two-spikes over
end

%add spikeAmp stuff
outputStruct.fullISI.value = fullISI;
outputStruct.fullSpikeAmpDiff.value = fullSpikeAmpDiff;

%get response ISI threshold
[blistQshort, baselineISI, blistQ10, blistQ90] = getResponseISIThreshold(blISI, blISI2);

%add the first few parameters, quantiles for baseline ISIs, and full ISI
%distribution
outputStruct.blistQ10.value = blistQ10;
outputStruct.blistQ90.value = blistQ90;
outputStruct.baselineISI_full.value = baselineISI;

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
        outputStruct.fullISI.units = 's';
        outputStruct.fullISI.type = 'combinedAcrossEpochs';
        %value already set

        outputStruct.fullSpikeAmpDiff.units = '';
        outputStruct.fullSpikeAmpDiff.type = 'combinedAcrossEpochs';
        %value already set;
        
        outputStruct.averageSpikeWaveform.units = '';
        outputStruct.averageSpikeWaveform.type = 'combinedAcrossEpochs';
        %value already set
        
        outputStruct.baselineRate.units = 'Hz';
        outputStruct.baselineRate.type = 'byEpoch';
        %value already set
        
        outputStruct.blistQ10.units = 's';
        outputStruct.blistQ10.type = 'singleValue';
        %value already set
        
        outputStruct.blistQ90.units = 's';
        outputStruct.blistQ90.type = 'singleValue';
        %value already set
        
        outputStruct.baselineISI_full.units = 's';
        outputStruct.baselineISI_full.type = 'combinedAcrossEpochs';
        %value already set
        
        outputStruct.ONSET_ISI_full.units = 's';
        outputStruct.ONSET_ISI_full.type = 'combinedAcrossEpochs';
        outputStruct.ONSET_ISI_full.value = [];
        
        outputStruct.OFFSET_ISI_full.units = 's';
        outputStruct.OFFSET_ISI_full.type = 'combinedAcrossEpochs';
        outputStruct.OFFSET_ISI_full.value = [];
        
        outputStruct.spikeCount_stimInterval.units = 'spikes';
        outputStruct.spikeCount_stimInterval.type = 'byEpoch';
        outputStruct.spikeCount_stimInterval.value = zeros(1,L);
        
        outputStruct.spikeRate_stimInterval.units = 'Hz';
        outputStruct.spikeRate_stimInterval.type = 'byEpoch';
        outputStruct.spikeRate_stimInterval.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_stimInterval_baselineSubtracted.units = 'spikes';
        outputStruct.spikeCount_stimInterval_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeCount_stimInterval_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.spikeRate_stimInterval_baselineSubtracted.units = 'Hz';
        outputStruct.spikeRate_stimInterval_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeRate_stimInterval_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.ONSETlatency.units = 's';
        outputStruct.ONSETlatency.type = 'byEpoch';
        outputStruct.ONSETlatency.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETlatency.units = 's';
        outputStruct.OFFSETlatency.type = 'byEpoch';
        outputStruct.OFFSETlatency.value = ones(1,L) * NaN;
        
        outputStruct.ONSETrespDuration.units = 's';
        outputStruct.ONSETrespDuration.type = 'byEpoch';
        outputStruct.ONSETrespDuration.value = zeros(1,L);
        
        outputStruct.OFFSETrespDuration.units = 's';
        outputStruct.OFFSETrespDuration.type = 'byEpoch';
        outputStruct.OFFSETrespDuration.value = zeros(1,L);
        
        outputStruct.ONSETspikes.units = 'spikes';
        outputStruct.ONSETspikes.type = 'byEpoch';
        outputStruct.ONSETspikes.value = zeros(1,L);
        
        outputStruct.OFFSETspikes.units = 'spikes';
        outputStruct.OFFSETspikes.type = 'byEpoch';
        outputStruct.OFFSETspikes.value = zeros(1,L);
        
        outputStruct.ONSETrespRate.units = 'Hz';
        outputStruct.ONSETrespRate.type = 'byEpoch';
        outputStruct.ONSETrespRate.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETrespRate.units = 'Hz';
        outputStruct.OFFSETrespRate.type = 'byEpoch';
        outputStruct.OFFSETrespRate.value = ones(1,L) * NaN;
        
        outputStruct.ONOFFindex.units = '';
        outputStruct.ONOFFindex.type = 'byEpoch';
        outputStruct.ONOFFindex.value = ones(1,L) * NaN;
        
        outputStruct.ONSETrespRate_baselineSubtracted.units = 'Hz';
        outputStruct.ONSETrespRate_baselineSubtracted.type = 'byEpoch';
        outputStruct.ONSETrespRate_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETrespRate_baselineSubtracted.units = 'Hz';
        outputStruct.OFFSETrespRate_baselineSubtracted.type = 'byEpoch';
        outputStruct.OFFSETrespRate_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.ONSETburstSpikes.units = 'spikes';
        outputStruct.ONSETburstSpikes.type = 'byEpoch';
        outputStruct.ONSETburstSpikes.value = zeros(1,L);
        
        outputStruct.ONSETnonBurstSpikes.units = 'spikes';
        outputStruct.ONSETnonBurstSpikes.type = 'byEpoch';
        outputStruct.ONSETnonBurstSpikes.value = zeros(1,L);
        
        outputStruct.ONSETburstDuration.units = 's';
        outputStruct.ONSETburstDuration.type = 'byEpoch';
        outputStruct.ONSETburstDuration.value = zeros(1,L);
        
        outputStruct.ONSETnonBurstDuration.units = 's';
        outputStruct.ONSETnonBurstDuration.type = 'byEpoch';
        outputStruct.ONSETnonBurstDuration.value = zeros(1,L);
        
        outputStruct.ONSETburstRate.units = 'Hz';
        outputStruct.ONSETburstRate.type = 'byEpoch';
        outputStruct.ONSETburstRate.value = ones(1,L) * NaN;
        
        outputStruct.ONSETnonBurstRate.units = 'Hz';
        outputStruct.ONSETnonBurstRate.type = 'byEpoch';
        outputStruct.ONSETnonBurstRate.value = ones(1,L) * NaN;
        
        outputStruct.ONSETburstNonBurstRatio_spikes.units = '';
        outputStruct.ONSETburstNonBurstRatio_spikes.type = 'byEpoch';
        outputStruct.ONSETburstNonBurstRatio_spikes.value = ones(1,L) * NaN;
        
        outputStruct.ONSETburstNonBurstRatio_duration.units = '';
        outputStruct.ONSETburstNonBurstRatio_duration.type = 'byEpoch';
        outputStruct.ONSETburstNonBurstRatio_duration.value = ones(1,L) * NaN;
        
        outputStruct.ONSETburstNonBurstRatio_rate.units = '';
        outputStruct.ONSETburstNonBurstRatio_rate.type = 'byEpoch';
        outputStruct.ONSETburstNonBurstRatio_rate.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETburstSpikes.units = 'spikes';
        outputStruct.OFFSETburstSpikes.type = 'byEpoch';
        outputStruct.OFFSETburstSpikes.value = zeros(1,L);
        
        outputStruct.OFFSETnonBurstSpikes.units = 'spikes';
        outputStruct.OFFSETnonBurstSpikes.type = 'byEpoch';
        outputStruct.OFFSETnonBurstSpikes.value = zeros(1,L);
        
        outputStruct.OFFSETburstDuration.units = 's';
        outputStruct.OFFSETburstDuration.type = 'byEpoch';
        outputStruct.OFFSETburstDuration.value = zeros(1,L);
        
        outputStruct.OFFSETnonBurstDuration.units = 's';
        outputStruct.OFFSETnonBurstDuration.type = 'byEpoch';
        outputStruct.OFFSETnonBurstDuration.value = zeros(1,L);
        
        outputStruct.OFFSETburstRate.units = 'Hz';
        outputStruct.OFFSETburstRate.type = 'byEpoch';
        outputStruct.OFFSETburstRate.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETnonBurstRate.units = 'Hz';
        outputStruct.OFFSETnonBurstRate.type = 'byEpoch';
        outputStruct.OFFSETnonBurstRate.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETburstNonBurstRatio_spikes.units = '';
        outputStruct.OFFSETburstNonBurstRatio_spikes.type = 'byEpoch';
        outputStruct.OFFSETburstNonBurstRatio_spikes.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETburstNonBurstRatio_duration.units = '';
        outputStruct.OFFSETburstNonBurstRatio_duration.type = 'byEpoch';
        outputStruct.OFFSETburstNonBurstRatio_duration.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETburstNonBurstRatio_rate.units = '';
        outputStruct.OFFSETburstNonBurstRatio_rate.type = 'byEpoch';
        outputStruct.OFFSETburstNonBurstRatio_rate.value = ones(1,L) * NaN;
        
        outputStruct.ONSETpeakInstantaneousFR.units = 'Hz';
        outputStruct.ONSETpeakInstantaneousFR.type = 'byEpoch';
        outputStruct.ONSETpeakInstantaneousFR.value = ones(1,L) * NaN;
        
        outputStruct.OFFSETpeakInstantaneousFR.units = 'Hz';
        outputStruct.OFFSETpeakInstantaneousFR.type = 'byEpoch';
        outputStruct.OFFSETpeakInstantaneousFR.value = ones(1,L) * NaN;
        
        outputStruct.ONSET_FRmax.units = 'Hz';
        outputStruct.ONSET_FRmax.type = 'singleValue';
        outputStruct.ONSET_FRmax.value = NaN;
        
        outputStruct.ONSET_FRrange.units = 'Hz';
        outputStruct.ONSET_FRrange.type = 'singleValue';
        outputStruct.ONSET_FRrange.value = NaN;
        
        outputStruct.ONSET_FRmaxLatency.units = 's';
        outputStruct.ONSET_FRmaxLatency.type = 'singleValue';
        outputStruct.ONSET_FRmaxLatency.value = NaN;
        
        outputStruct.ONSET_FRrampLatency.units = 's';
        outputStruct.ONSET_FRrampLatency.type = 'singleValue';
        outputStruct.ONSET_FRrampLatency.value = NaN;
        
        outputStruct.OFFSET_FRmax.units = 'Hz';
        outputStruct.OFFSET_FRmax.type = 'singleValue';
        outputStruct.OFFSET_FRmax.value = NaN;
        
        outputStruct.OFFSET_FRrange.units = 'Hz';
        outputStruct.OFFSET_FRrange.type = 'singleValue';
        outputStruct.OFFSET_FRrange.value = NaN;
        
        outputStruct.OFFSET_FRmaxLatency.units = 's';
        outputStruct.OFFSET_FRmaxLatency.type = 'singleValue';
        outputStruct.OFFSET_FRmaxLatency.value = NaN;
        
        outputStruct.OFFSET_FRrampLatency.units = 's';
        outputStruct.OFFSET_FRrampLatency.type = 'singleValue';
        outputStruct.OFFSET_FRrampLatency.value = NaN;
        
        outputStruct.ONSETpsth.units = 'Hz';
        outputStruct.ONSETpsth.type = 'combinedAcrossEpochs';
        outputStruct.ONSETpsth.value = [];
        
        outputStruct.OFFSETpsth.units = 'Hz';
        outputStruct.OFFSETpsth.type = 'combinedAcrossEpochs';
        outputStruct.OFFSETpsth.value = [];
        
        outputStruct.ONSET_FRrangeFrac.units = 'Hz';
        outputStruct.ONSET_FRrangeFrac.type = 'singleValue';
        outputStruct.ONSET_FRrangeFrac.value = NaN;
        
        outputStruct.OFFSET_FRrangeFrac.units = 'Hz';
        outputStruct.OFFSET_FRrangeFrac.type = 'singleValue';
        outputStruct.OFFSET_FRrangeFrac.value = NaN;
    end
    
    curEpoch = cellData.epochs(epochInd(i));
    %get spike times (in units of seconds from startTime
    spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName);
    spikeTimes = spikeTimes - stimStart;
    spikeTimes = spikeTimes / sampleRate;
    
    %TEMP HACK: This is to remove crazy refractory preiod violations from the spike detector
    if  length(spikeTimes) >= 2
        ISItest = diff(spikeTimes);
        spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
    end;
    % % %
    
    %now we go through each response type in its own block
    
    %count spikes in stimulus interval
    spikeCount = length(find(spikeTimes >= intervalStart & spikeTimes < intervalEnd));
    outputStruct.spikeCount_stimInterval.value(i) = spikeCount;
    outputStruct.spikeRate_stimInterval.value(i) = spikeCount/responseIntervalLen;
    
    %subtract baseline
    spikeCount_baselineSubtracted = spikeCount - meanBaselineRate/responseIntervalLen;
    outputStruct.spikeCount_stimInterval_baselineSubtracted.value(i) = spikeCount_baselineSubtracted;
    outputStruct.spikeRate_stimInterval_baselineSubtracted.value(i) = spikeCount_baselineSubtracted/responseIntervalLen;
    
    %find response start and end times based on ISIs: This is for a
    %stimulus that starts and ends and a particular time
    %save all values for calculating PSTH stuff at the end
    [ONSETresponseStartTime, ONSETresponseEndTime, OFFSETresponseStartTime, OFFSETresponseEndTime] = ...
        enhancedFiringResponse(spikeTimes, intervalStart, intervalEnd, blistQshort);
    if ~isempty(ONSETresponseStartTime), ONSETresponseStartTime_all(i) = ONSETresponseStartTime; end
    if ~isempty(ONSETresponseEndTime), ONSETresponseEndTime_all(i) = ONSETresponseEndTime; end
    if ~isempty(OFFSETresponseStartTime), OFFSETresponseStartTime_all(i) = OFFSETresponseStartTime; end
    if ~isempty(OFFSETresponseEndTime), OFFSETresponseEndTime_all(i) = OFFSETresponseEndTime; end
    
    %onset latency, spike count, duration, fullISI, and mean rate
    if ~isempty(ONSETresponseStartTime)
        outputStruct.ONSETlatency.value(i) = ONSETresponseStartTime - intervalStart;
        if ~isempty(ONSETresponseEndTime)
            ONSETspikes = sum((spikeTimes >= ONSETresponseStartTime) & (spikeTimes <= ONSETresponseEndTime));
            outputStruct.ONSET_ISI_full.value = diff(spikeTimes((spikeTimes >= ONSETresponseStartTime) & (spikeTimes <= ONSETresponseEndTime)));
            outputStruct.ONSETrespDuration.value(i) = ONSETresponseEndTime - ONSETresponseStartTime;
            outputStruct.ONSETrespRate.value(i) = ONSETspikes / outputStruct.ONSETrespDuration.value(i);
            outputStruct.ONSETrespRate_baselineSubtracted.value(i) = outputStruct.ONSETrespRate.value(i) - meanBaselineRate;
        end
        outputStruct.ONSETspikes.value(i) = ONSETspikes;
    end
    
    %offset latency, spike count, duration, fullISI, and mean rate
    if ~isempty(OFFSETresponseStartTime)
        outputStruct.OFFSETlatency.value(i) = OFFSETresponseStartTime - intervalEnd;
        if ~isempty(OFFSETresponseEndTime)
            OFFSETspikes = sum((spikeTimes >= OFFSETresponseStartTime) & (spikeTimes <= OFFSETresponseEndTime));
            outputStruct.OFFSET_ISI_full.value = diff(spikeTimes((spikeTimes >= OFFSETresponseStartTime) & (spikeTimes <= OFFSETresponseEndTime)));
            outputStruct.OFFSETrespDuration.value(i) = OFFSETresponseEndTime - OFFSETresponseStartTime;
            outputStruct.OFFSETrespRate.value(i) = OFFSETspikes / outputStruct.OFFSETrespDuration.value(i);
            outputStruct.OFFSETrespRate_baselineSubtracted.value(i) = outputStruct.OFFSETrespRate.value(i) - meanBaselineRate;
        end
        outputStruct.OFFSETspikes.value(i) = OFFSETspikes;
    end
    
    outputStruct.ONOFFindex.value(i) = (outputStruct.ONSETspikes.value(i) - outputStruct.OFFSETspikes.value(i)) / ...
        (outputStruct.ONSETspikes.value(i) + outputStruct.OFFSETspikes.value(i));
    
    %burst detection ONSET and OFFSET
    %ONSET
    if ~isempty(ONSETresponseStartTime)
        ONSET_burstEndTime = burstInResponse(spikeTimes, ONSETresponseStartTime, ONSETresponseEndTime);
        if ~isnan(ONSET_burstEndTime)
            ONSET_burstSpikes = sum((spikeTimes >= ONSETresponseStartTime) & (spikeTimes <= ONSET_burstEndTime));
            ONSET_nonBurstSpikes = sum((spikeTimes > ONSET_burstEndTime) & (spikeTimes <= ONSETresponseEndTime));
            outputStruct.ONSETburstSpikes.value(i) = ONSET_burstSpikes;
            outputStruct.ONSETnonBurstSpikes.value(i) = ONSET_nonBurstSpikes;
            outputStruct.ONSETburstDuration.value(i) = ONSET_burstEndTime - ONSETresponseStartTime;
            outputStruct.ONSETnonBurstDuration.value(i) = ONSETresponseEndTime - ONSET_burstEndTime;
            
            outputStruct.ONSETburstRate.value(i) = ONSET_burstSpikes / outputStruct.ONSETburstDuration.value(i);
            outputStruct.ONSETnonBurstRate.value(i) = ONSET_nonBurstSpikes / outputStruct.ONSETnonBurstDuration.value(i);
            
            outputStruct.ONSETburstNonBurstRatio_spikes.value(i) = ONSET_burstSpikes ./ ONSET_nonBurstSpikes;
            outputStruct.ONSETburstNonBurstRatio_duration.value(i) = outputStruct.ONSETburstDuration.value(i) / outputStruct.ONSETnonBurstDuration.value(i);
            outputStruct.ONSETburstNonBurstRatio_rate.value(i) = outputStruct.ONSETburstRate.value(i) / outputStruct.ONSETnonBurstRate.value(i);
        end
    end
    %OFFSET
    if ~isempty(OFFSETresponseStartTime)
        OFFSET_burstEndTime = burstInResponse(spikeTimes, OFFSETresponseStartTime, OFFSETresponseEndTime);
        if ~isnan(OFFSET_burstEndTime)
            OFFSET_burstSpikes = sum((spikeTimes >= OFFSETresponseStartTime) & (spikeTimes <= OFFSET_burstEndTime));
            OFFSET_nonBurstSpikes = sum((spikeTimes > OFFSET_burstEndTime) & (spikeTimes <= OFFSETresponseEndTime));
            outputStruct.OFFSETburstSpikes.value(i) = OFFSET_burstSpikes;
            outputStruct.OFFSETnonBurstSpikes.value(i) = OFFSET_nonBurstSpikes;
            outputStruct.OFFSETburstDuration.value(i) = OFFSET_burstEndTime - OFFSETresponseStartTime;
            outputStruct.OFFSETnonBurstDuration.value(i) = OFFSETresponseEndTime - OFFSET_burstEndTime;
            
            outputStruct.OFFSETburstRate.value(i) = OFFSET_burstSpikes / outputStruct.OFFSETburstDuration.value(i);
            outputStruct.OFFSETnonBurstRate.value(i) = OFFSET_nonBurstSpikes / outputStruct.OFFSETnonBurstDuration.value(i);
            
            outputStruct.OFFSETburstNonBurstRatio_spikes.value(i) = OFFSET_burstSpikes ./ OFFSET_nonBurstSpikes;
            outputStruct.OFFSETburstNonBurstRatio_duration.value(i) = outputStruct.OFFSETburstDuration.value(i) / outputStruct.OFFSETnonBurstDuration.value(i);
            outputStruct.OFFSETburstNonBurstRatio_rate.value(i) = outputStruct.OFFSETburstRate.value(i) / outputStruct.OFFSETnonBurstRate.value(i);
        end
    end
    
    %peak instantaneous firing rate
    ONISI = outputStruct.ONSET_ISI_full.value;
    if  length(ONISI) >=2
        ONISI2 = ( ONISI(1:end-1) + ONISI(2:end) );
        outputStruct.ONSETpeakInstantaneousFR.value(i) = max(2./ONISI2);
    end
    OFFISI = outputStruct.OFFSET_ISI_full.value;
    if  length(OFFISI) >=2
        OFFISI2 = ( OFFISI(1:end-1) + OFFISI(2:end) );
        outputStruct.OFFSETpeakInstantaneousFR.value(i) = max(2./OFFISI2);
    end
    
end %end loop over epochs

%PSTH-based parameters
ONSETresponseStartTime_min = min(ONSETresponseStartTime_all);
ONSETresponseEndTime_max = max(ONSETresponseEndTime_all);
OFFSETresponseStartTime_min = min(OFFSETresponseStartTime_all);
OFFSETresponseEndTime_max = max(OFFSETresponseEndTime_all);
[psth, xvals] = cellData.getPSTH(epochInd, ip.Results.BinWidth, ip.Results.DeviceName);
%ONSET
if ONSETresponseEndTime_max > ONSETresponseStartTime_min
    xvals_onset = xvals(xvals >= ONSETresponseStartTime_min & xvals < ONSETresponseEndTime_max);
    psth_onset = psth(xvals >= ONSETresponseStartTime_min & xvals < ONSETresponseEndTime_max);
    outputStruct.ONSETpsth.value = psth_onset;
    [outputStruct.ONSET_FRmax.value, maxLoc] = max(psth_onset);
    if ~isempty(maxLoc)
        maxLoc = maxLoc(1); 
        outputStruct.ONSET_FRmaxLatency.value = xvals_onset(maxLoc);
    end
    outputStruct.ONSET_FRrampLatency.value = outputStruct.ONSET_FRmaxLatency.value - nanmedian(outputStruct.ONSETlatency.value); %latency from start to peak
    outputStruct.ONSET_FRrange.value = outputStruct.ONSET_FRmax.value - min(psth_onset(maxLoc:end)); %range from max to end
    outputStruct.ONSET_FRrangeFrac.value = outputStruct.ONSET_FRrange.value / outputStruct.ONSET_FRmax.value;
end
%OFFSET
if OFFSETresponseEndTime_max > OFFSETresponseStartTime_min
    xvals_offset = xvals(xvals >= OFFSETresponseStartTime_min & xvals < OFFSETresponseEndTime_max);
    psth_offset = psth(xvals >= OFFSETresponseStartTime_min & xvals < OFFSETresponseEndTime_max);
    outputStruct.OFFSETpsth.value = psth_offset;
    [outputStruct.OFFSET_FRmax.value, maxLoc] = max(psth_offset);
    if ~isempty(maxLoc)
        maxLoc = maxLoc(1); 
        outputStruct.OFFSET_FRmaxLatency.value = xvals_offset(maxLoc) - OFFSETresponseStartTime;
    end
    outputStruct.OFFSET_FRrampLatency.value = outputStruct.OFFSET_FRmaxLatency.value - nanmedian(outputStruct.OFFSETlatency.value); %latency from start to peak
    outputStruct.OFFSET_FRrange.value = outputStruct.OFFSET_FRmax.value - min(psth_offset(maxLoc:end)); %range from max to end
    outputStruct.OFFSET_FRrangeFrac.value = outputStruct.OFFSET_FRrange.value / outputStruct.OFFSET_FRmax.value;
end

end


