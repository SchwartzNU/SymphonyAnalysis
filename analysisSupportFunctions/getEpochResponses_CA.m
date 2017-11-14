function outputStruct = getEpochResponses_CA(cellData, epochInd, varargin)
ip = inputParser;
ip.KeepUnmatched = true;
ip.addParamValue('DeviceName', 'Amplifier_Ch1', @(x)ischar(x));
ip.addParamValue('BaselineTime', 0, @(x)isnumeric(x)); %ms - overrides preTime for baseline interval calculation, use if preTime is missing
ip.addParamValue('StartTime', 0, @(x)isnumeric(x)); %ms with 0 as stimulus start time
ip.addParamValue('EndTime', 0, @(x)isnumeric(x)); %ms
ip.addParamValue('LowPassFreq', 30, @(x)isnumeric(x)); %Hz
ip.addParamValue('BinWidth', 10, @(x)isnumeric(x)); %ms
ip.addParamValue('EndOffset', 0, @(x)isnumeric(x)); %ms
ip.addParamValue('FitPSTH', 0, @(x)isnumeric(x)); %number of peaks to fit in PSTH

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
if strcmp(sampleEpoch.get('ampMode'), 'Cell attached')
    [spikeAmps_all, ~, averageWaveform] = getSpikeAmplitudesForEpochs(cellData, epochInd, ip.Results.DeviceName);
    outputStruct.averageSpikeWaveform.value = averageWaveform;
else %current clamp
    spikeAmps_all = [];
    outputStruct.averageSpikeWaveform.value = [];
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
        
        try
            tailTime = curEpoch.attributes('tailTime')* 1E-3; %Adam 11/14/15
        catch
            tailTime = 0;
        end;
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
        if ~isempty(spikeAmps_all)
            spikeAmps_all{i} = spikeAmps_all{i}([(ISItest > 0.0015) true]);
        end
        spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
    end;
    fullISI = [fullISI, cumsum(diff(spikeTimes))];
    %fraction difference of spikeAmps
    if ~isempty(spikeAmps_all)
        spikeAmps_all{i} = spikeAmps_all{i} / max(spikeAmps_all{i});
        fullSpikeAmpDiff = [fullSpikeAmpDiff; cumsum(diff(spikeAmps_all{i}))];
    end
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
        
        outputStruct.spikeCount_100ms_around_PSTH_peak.units = 'spikes';
        outputStruct.spikeCount_100ms_around_PSTH_peak.type = 'byEpoch';
        outputStruct.spikeCount_100ms_around_PSTH_peak.value = zeros(1,L);
        
        outputStruct.spikeCount_stimTo100ms.units = 'spikes';
        outputStruct.spikeCount_stimTo100ms.type = 'byEpoch';
        outputStruct.spikeCount_stimTo100ms.value = zeros(1,L);
        
        outputStruct.spikeCount_stimTo200ms.units = 'spikes';
        outputStruct.spikeCount_stimTo200ms.type = 'byEpoch';
        outputStruct.spikeCount_stimTo200ms.value = zeros(1,L);
        
        outputStruct.spikeCount_stimAfter100ms.units = 'spikes';
        outputStruct.spikeCount_stimAfter100ms.type = 'byEpoch';
        outputStruct.spikeCount_stimAfter100ms.value = zeros(1,L);
        
        outputStruct.spikeCount_stimAfter200ms.units = 'spikes';
        outputStruct.spikeCount_stimAfter200ms.type = 'byEpoch';
        outputStruct.spikeCount_stimAfter200ms.value = zeros(1,L);
        
        outputStruct.spikeCount_stimAfter500ms.units = 'spikes';
        outputStruct.spikeCount_stimAfter500ms.type = 'byEpoch';
        outputStruct.spikeCount_stimAfter500ms.value = zeros(1,L);        
        
        outputStruct.spikeCount_stimToEnd.units = 'spikes';
        outputStruct.spikeCount_stimToEnd.type = 'byEpoch';
        outputStruct.spikeCount_stimToEnd.value = zeros(1,L);
        
        outputStruct.spikeCount_stimInterval.units = 'spikes';
        outputStruct.spikeCount_stimInterval.type = 'byEpoch';
        outputStruct.spikeCount_stimInterval.value = zeros(1,L);
        
        outputStruct.spikeCount_afterStim.units = 'spikes';
        outputStruct.spikeCount_afterStim.type = 'byEpoch';
        outputStruct.spikeCount_afterStim.value = zeros(1,L);        
        
        outputStruct.spikeRate_stimInterval.units = 'Hz';
        outputStruct.spikeRate_stimInterval.type = 'byEpoch';
        outputStruct.spikeRate_stimInterval.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_ONSET_after200ms.units = 'spikes';
        outputStruct.spikeCount_ONSET_after200ms.type = 'byEpoch';
        outputStruct.spikeCount_ONSET_after200ms.value = ones(1,L) * NaN;
        
        % Adam 12/6/15
        outputStruct.spikeCount_ONSET_after200ms_baselineSubtracted.units = 'spikes';
        outputStruct.spikeCount_ONSET_after200ms_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeCount_ONSET_after200ms_baselineSubtracted.value = ones(1,L) * NaN;
        %
        
        outputStruct.spikeCount_ONSET_400ms.units = 'spikes';
        outputStruct.spikeCount_ONSET_400ms.type = 'byEpoch';
        outputStruct.spikeCount_ONSET_400ms.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_ONSET_200ms.units = 'spikes';
        outputStruct.spikeCount_ONSET_200ms.type = 'byEpoch';
        outputStruct.spikeCount_ONSET_200ms.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_OFFSET_400ms.units = 'spikes';
        outputStruct.spikeCount_OFFSET_400ms.type = 'byEpoch';
        outputStruct.spikeCount_OFFSET_400ms.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_ONSET_400ms_baselineSubtracted.units = 'spikes';
        outputStruct.spikeCount_ONSET_400ms_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeCount_ONSET_400ms_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_OFFSET_400ms_baselineSubtracted.units = 'spikes';
        outputStruct.spikeCount_OFFSET_400ms_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeCount_OFFSET_400ms_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_stimInterval_baselineSubtracted.units = 'spikes';
        outputStruct.spikeCount_stimInterval_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeCount_stimInterval_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.spikeRate_stimInterval_baselineSubtracted.units = 'Hz';
        outputStruct.spikeRate_stimInterval_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeRate_stimInterval_baselineSubtracted.value = ones(1,L) * NaN;
        
        outputStruct.spikeCount_tailInterval_baselineSubtracted.units = 'Hz';
        outputStruct.spikeCount_tailInterval_baselineSubtracted.type = 'byEpoch';
        outputStruct.spikeCount_tailInterval_baselineSubtracted.value = ones(1,L) * NaN;
        
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
        %%% Adam 5/15/17
        outputStruct.stimInt20_FRmax.units = 'Hz';
        outputStruct.stimInt20_FRmax.type = 'singleValue';
        outputStruct.stimInt20_FRmax.value = NaN;
        %%%%%
        outputStruct.ONSET_FRhalfMaxLatency.units = 's';
        outputStruct.ONSET_FRhalfMaxLatency.type = 'singleValue';
        outputStruct.ONSET_FRhalfMaxLatency.value = NaN;
        
%         %%%%Adam 9/22/15    
%         outputStruct.ONSET_FRhalfMaxSusLatency.units = 's';
%         outputStruct.ONSET_FRhalfMaxSusLatency.type = 'singleValue';
%         outputStruct.ONSET_FRhalfMaxSusLatency.value = NaN;
%         %%%%
        
        outputStruct.ONSET_FRrampLatency.units = 's';
        outputStruct.ONSET_FRrampLatency.type = 'singleValue';
        outputStruct.ONSET_FRrampLatency.value = NaN;
        
        %Adam 8/27/15
        outputStruct.centerOfMassLatency.units = 's';
        outputStruct.centerOfMassLatency.type = 'singleValue';
        outputStruct.centerOfMassLatency.value = NaN;
        %%%
       
        
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
        
        outputStruct.ONSETsuppressionTime.units = 's';
        outputStruct.ONSETsuppressionTime.type = 'singleValue';
        outputStruct.ONSETsuppressionTime.value = 0;
        
        outputStruct.ONSETsuppressedSpikes.units = 'spikes';
        outputStruct.ONSETsuppressedSpikes.type = 'singleValue';
        outputStruct.ONSETsuppressedSpikes.value = 0;
        
        outputStruct.OFFSETsuppressionTime.units = 's';
        outputStruct.OFFSETsuppressionTime.type = 'singleValue';
        outputStruct.OFFSETsuppressionTime.value = 0;
        
        outputStruct.OFFSETsuppressedSpikes.units = 'spikes';
        outputStruct.OFFSETsuppressedSpikes.type = 'singleValue';
        outputStruct.OFFSETsuppressedSpikes.value = 0;
        
        %Amurta 12/10/15
        outputStruct.ONSETtransPeak.units = 'Hz';
        outputStruct.ONSETtransPeak.type = 'singleValue';
        outputStruct.ONSETtransPeak.value = 0;
        
        %Amurta 12/10/15
        outputStruct.ONSETsusPeak.units = 'Hz';
        outputStruct.ONSETsusPeak.type = 'singleValue';
        outputStruct.ONSETsusPeak.value = 0;
        
        %Amurta 12/10/15
        outputStruct.ONSETpause.units = 'Hz';
        outputStruct.ONSETpause.type = 'singleValue';
        outputStruct.ONSETpause.value = 0;
        
        %Amurta 12/10/15
        outputStruct.ONSETsuspauseDiff.units = 'Hz';
        outputStruct.ONSETsuspauseDiff.type = 'singleValue';
        outputStruct.ONSETsuspauseDiff.value = 0;
        
        %Amurta 12/10/15
        outputStruct.ONSET_ISI_peak.units = 'ms';
        outputStruct.ONSET_ISI_peak.type = 'singleValue';
        outputStruct.ONSET_ISI_peak.value = [];
        
        %Amurta 12/10/15
        outputStruct.ONSET_ISI_peakLatency.units = 'ms';
        outputStruct.ONSET_ISI_peakLatency.type = 'singleValue';
        outputStruct.ONSET_ISI_peakLatency.value = [];
        
        % Sam 4/7/17
        outputStruct.spikeCount_mbLeading.units = 'spikes';
        outputStruct.spikeCount_mbLeading.type = 'byEpoch';
        outputStruct.spikeCount_mbLeading.value = zeros(1,L);
        
        % Sam 4/7/17
        outputStruct.spikeCount_mbTrailing.units = 'spikes';
        outputStruct.spikeCount_mbTrailing.type = 'byEpoch';
        outputStruct.spikeCount_mbTrailing.value = zeros(1,L);
        
    end
    
    curEpoch = cellData.epochs(epochInd(i));
    %get spike times (in units of seconds from startTime
    spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName);
    spikeTimes = spikeTimes - stimStart;
    spikeTimes = spikeTimes / sampleRate;
    
    %TEMP HACK: This is to remove crazy refractory preiod violations from the spike detector
    % removed by fixing the spike detector code, and this code never worked anyway
%     if length(spikeTimes) >= 2
%         ISItest = diff(spikeTimes);
%         spikeTimes = spikeTimes([(ISItest > 0.0015) true]);
%     end;
    % % %
    
    %now we go through each response type in its own block
    
    %count spikes in stimulus interval
    spikeCount = sum(spikeTimes >= intervalStart & spikeTimes < intervalEnd);
    outputStruct.spikeCount_stimInterval.value(i) = spikeCount;
    outputStruct.spikeRate_stimInterval.value(i) = spikeCount/responseIntervalLen;
    
    %count spikes after stimulus end
    spikeCount = sum(spikeTimes >= intervalEnd);
    outputStruct.spikeCount_afterStim.value(i) = spikeCount;
    
    %count spikes in stimulus to end interval
    spikeCount = sum(spikeTimes >= intervalStart);
    outputStruct.spikeCount_stimToEnd.value(i) = spikeCount;
    
    %count spikes in some other intervals
    spikeCount = sum(spikeTimes >= intervalStart & spikeTimes < intervalStart + 0.1);
    outputStruct.spikeCount_stimTo100ms.value(i) = spikeCount;
    spikeCount = sum(spikeTimes >= intervalStart & spikeTimes < intervalStart + 0.2);
    outputStruct.spikeCount_stimTo200ms.value(i) = spikeCount;
    spikeCount = sum(spikeTimes >= intervalStart + 0.1);
    outputStruct.spikeCount_stimAfter100ms.value(i) = spikeCount;
    spikeCount = sum(spikeTimes >= intervalStart + 0.2);
    outputStruct.spikeCount_stimAfter200ms.value(i) = spikeCount;
    spikeCount = sum(spikeTimes >= intervalStart + 0.5);
    outputStruct.spikeCount_stimAfter500ms.value(i) = spikeCount;    
    
    %count spikes in 400 ms after onset and offset
    if responseIntervalLen >= 0.4
        spikeCount = sum(spikeTimes >= intervalStart & spikeTimes < intervalStart + 0.4);
        outputStruct.spikeCount_ONSET_400ms.value(i) = spikeCount;
    end
    if intervalEnd + 0.4 <= xvals(end)
        spikeCount = sum(spikeTimes >= intervalEnd & spikeTimes < intervalEnd + 0.4);
        outputStruct.spikeCount_OFFSET_400ms.value(i) = spikeCount;
    end
    
    %count spikes in 200 ms after onset
    if responseIntervalLen >= 0.2
        spikeCount = sum(spikeTimes >= intervalStart & spikeTimes < intervalStart + 0.2);
        outputStruct.spikeCount_ONSET_200ms.value(i) = spikeCount;
    end
    
    %count spikes 200 ms after onset (removing initial burst from SbC)
    if responseIntervalLen > 0.2
        spikeCount = sum(spikeTimes >= intervalStart + 0.2 & spikeTimes < intervalEnd);
        outputStruct.spikeCount_ONSET_after200ms.value(i) = spikeCount;
    end
    
    %count spikes 100 ms offset till epoch end
    tailSpikeCount = sum(spikeTimes >= intervalEnd + 0.1 & spikeTimes < intervalEnd+tailTime);
    
    % moving bar leading and trailing edges (approximately at this point)
    centerTime = (intervalEnd - intervalStart)/2 + .2;
    outputStruct.spikeCount_mbLeading.value(i) = sum(spikeTimes >= intervalStart & spikeTimes < centerTime);
    outputStruct.spikeCount_mbTrailing.value(i) = sum(spikeTimes >= centerTime & spikeTimes < intervalEnd);
    
    %subtract baseline
    spikeCount_baselineSubtracted = spikeCount - meanBaselineRate.*responseIntervalLen; %division?? should be *. luckily it's usually 1.
    outputStruct.spikeCount_stimInterval_baselineSubtracted.value(i) = spikeCount_baselineSubtracted;
    outputStruct.spikeRate_stimInterval_baselineSubtracted.value(i) = spikeCount_baselineSubtracted/responseIntervalLen;
    
    tailSpikeCount_baselineSubtracted = tailSpikeCount - meanBaselineRate*(tailTime-0.1);
    outputStruct.spikeCount_tailInterval_baselineSubtracted.value(i) = tailSpikeCount_baselineSubtracted;
    
    %subtract baseline
    outputStruct.spikeCount_ONSET_400ms_baselineSubtracted.value(i) = outputStruct.spikeCount_ONSET_400ms.value(i) - meanBaselineRate.*0.4; %should be *.
    outputStruct.spikeCount_OFFSET_400ms_baselineSubtracted.value(i) = outputStruct.spikeCount_OFFSET_400ms.value(i) - meanBaselineRate.*0.4; %should be *.
    
    outputStruct.spikeCount_ONSET_after200ms_baselineSubtracted.value(i) = ...
        outputStruct.spikeCount_ONSET_after200ms.value(i) - meanBaselineRate*(responseIntervalLen-0.2);
    
    
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
            outputStruct.ONSETrespRate.value(i) = ONSETspikes / outputStruct.ONSETrespDuration.value(i); %fix nan and inf here!
            outputStruct.ONSETrespRate_baselineSubtracted.value(i) = outputStruct.ONSETrespRate.value(i) - meanBaselineRate;
        end
        outputStruct.ONSETspikes.value(i) = ONSETspikes;
        %Amurta
        if (i == 1)
            ISI_100msTo500ms = diff(spikeTimes((spikeTimes >= intervalStart + 0.1) & (spikeTimes <= intervalStart + 0.5)));
            [outputStruct.ONSET_ISI_peak.value, ONSET_ISI_peak_index] = max(ISI_100msTo500ms);
            outputStruct.ONSET_ISI_peak.value = outputStruct.ONSET_ISI_peak.value * 1E3;
            spikeTimes_ONSET = spikeTimes(spikeTimes >= 0 & spikeTimes <= 1);
            outputStruct.ONSET_ISI_peakLatency.value = (spikeTimes_ONSET(ONSET_ISI_peak_index) - intervalStart) * 1E3;
        end
        %Amurta
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
[psth20, xvals20] = cellData.getPSTH(epochInd, 20, ip.Results.DeviceName);

%%%%%%%%%Adam 8/27/15 temp hack centerOfMassLatency
respOffs = 0.15;
stimXvals = xvals((xvals >= respOffs)&(xvals <= 1 + respOffs)); 
stimPsth = psth((xvals >= respOffs)&(xvals <= 1 + respOffs)); 
comTime = sum(stimXvals.*stimPsth)/sum(stimPsth);
outputStruct.centerOfMassLatency.value = comTime;
%%%%%%%%%%%Adam 5/15/17 
%stimXvals20 = xvals20((xvals20 >= intervalStart)&(xvals20 <= intervalEnd)); 
stimPsth20 = psth20((xvals20 >= intervalStart)&(xvals20 <= intervalEnd));
outputStruct.stimInt20_FRmax.value = max(stimPsth20);
%%%%%

%PSTH fit
if ip.Results.FitPSTH > 0
    outputStruct.spikeCount_peak1.units = 'spikes';
    outputStruct.spikeCount_peak1.type = 'byEpoch';
    outputStruct.spikeCount_peak1.value = zeros(1,L);
    
    outputStruct.latencyTo_peak1.units = 's';
    outputStruct.latencyTo_peak1.type = 'singleValue';
    outputStruct.latencyTo_peak1.value = NaN;

    [params_fit, PSTH_fit] = PSTH_fitter_sequential(psth, ip.Results.FitPSTH);

    outputStruct.PSTH_fit.units = 'Hz';
    outputStruct.PSTH_fit.type = 'combinedAcrossEpochs';
    outputStruct.PSTH_fit.value = PSTH_fit;
    
    span = length(psth);
    spCount_peak1 = zeros(1,L);
    fitVals_p1 = raisedCosine(params_fit(1,:), span);
    ind_p1 = find(fitVals_p1>0);
    
    if ip.Results.FitPSTH == 2 %split spikes into peak1 and peak2
        outputStruct.spikeCount_peak2.units = 'spikes';
        outputStruct.spikeCount_peak2.type = 'byEpoch';
        outputStruct.spikeCount_peak2.value = zeros(1,L);
        
        outputStruct.latencyTo_peak2.units = 's';
        outputStruct.latencyTo_peak2.type = 'singleValue';
        outputStruct.latencyTo_peak2.value = NaN;
                
        spCount_peak2 = zeros(1,L);
        
        fitVals_p2 = raisedCosine(params_fit(2,:), span);
        ind_p2 = find(fitVals_p2>0);
        
        if ~isempty(ind_p1) && ~isempty(ind_p2)
            start_p1 = xvals(ind_p1(1));
            end_p1 = xvals(ind_p1(end));
            start_p2 = xvals(ind_p2(1));
            end_p2 = xvals(ind_p2(end));
            
            for i=1:L
                curEpoch = cellData.epochs(epochInd(i));
                sp = curEpoch.getSpikes(ip.Results.DeviceName);
                sp = sp - stimStart;
                sp = sp / sampleRate;
                spCount_peak1(i) = length(find(sp>=start_p1 & sp <= end_p1));
                spCount_peak2(i) = length(find(sp>=start_p2 & sp <= end_p2));
            end
        end
        outputStruct.spikeCount_peak1.value = spCount_peak1;
        outputStruct.spikeCount_peak2.value = spCount_peak2;
        [~, peak1_ind] = max(fitVals_p1);
        if ~isempty(peak1_ind)
            outputStruct.latencyTo_peak1.value = xvals(peak1_ind(1));
        end        
        [~, peak2_ind] = max(fitVals_p2);
        if ~isempty(peak2_ind)
            outputStruct.latencyTo_peak1.value = xvals(peak2_ind(1));
        end
    else % 1 peak
        if ~isempty(ind_p1) 
            start_p1 = xvals(ind_p1(1));
            end_p1 = xvals(ind_p1(end));
            
            for i=1:L
                curEpoch = cellData.epochs(epochInd(i));
                sp = curEpoch.getSpikes(ip.Results.DeviceName);
                sp = sp - stimStart;
                sp = sp / sampleRate;
                spCount_peak1(i) = length(find(sp>=start_p1 & sp <= end_p1));
            end
        end
        outputStruct.spikeCount_peak1.value = spCount_peak1;
        [~, peak1_ind] = max(fitVals_p1);
        if ~isempty(peak1_ind)
            outputStruct.latencyTo_peak1.value = xvals(peak1_ind(1));
        end
    end
        
end



%ONSET
if ONSETresponseEndTime_max > ONSETresponseStartTime_min
    xvals_onset = xvals(xvals >= ONSETresponseStartTime_min & xvals < ONSETresponseEndTime_max);
    psth_onset = psth(xvals >= ONSETresponseStartTime_min & xvals < ONSETresponseEndTime_max);
    xvals_stimToEnd = xvals(xvals >= 0);
    psth_stimToEnd = psth(xvals >= 0);
    %Amurta
    transEndTime = 0.2; %s %duration of transient response
    pauseStart = 0.1; %s
    pauseEnd = 0.3; %s
    susStart = 0.3; %s
    psth_trans = psth(xvals >= 0 & xvals <= transEndTime);
    outputStruct.ONSETtransPeak.value = max(psth_trans);
    psth_pause = psth(xvals >= pauseStart & xvals <= pauseEnd);
    outputStruct.ONSETpause.value = min(psth_pause);
    psth_sus = psth(xvals >= susStart & xvals <= 1);
    outputStruct.ONSETsusPeak.value = max(psth_sus);
    outputStruct.ONSETsuspauseDiff.value = max(psth_sus) - min(psth_pause);
    %Amurta
    outputStruct.ONSETpsth.value = psth_onset;
    [outputStruct.ONSET_FRmax.value, maxLoc] = max(psth_onset);
    if ~isempty(maxLoc)
        maxLoc = maxLoc(1);
        outputStruct.ONSET_FRmaxLatency.value = xvals_onset(maxLoc);
    end

    outputStruct.ONSET_FRrampLatency.value = outputStruct.ONSET_FRmaxLatency.value - nanmedian(outputStruct.ONSETlatency.value); %latency from start to peak
    FRthres = outputStruct.ONSET_FRmax.value / 2; %half max
    if FRthres>0
        outputStruct.ONSET_FRhalfMaxLatency.value = min(xvals_stimToEnd(getThresCross(psth_stimToEnd, FRthres, 1)));
%        outputStruct.ONSET_FRhalfMaxSusLatency.value = min(xvals_stimToEnd(getSustainedThresCross(psth_onset))); % Adam 9/22/15 %2/14/16 changed "PSTH_onset" to "psth_stimToEnd"
        outputStruct.ONSET_FRrange.value = outputStruct.ONSET_FRmax.value - min(psth_onset(maxLoc:end)); %range from max to end
        outputStruct.ONSET_FRrangeFrac.value = outputStruct.ONSET_FRrange.value / outputStruct.ONSET_FRmax.value;
    end
    if outputStruct.ONSET_FRmaxLatency.value > 0
        minTime = xvals_onset(maxLoc) - 0.05;
        maxTime = xvals_onset(maxLoc) + 0.05;
        L = length(epochInd);
        for i=1:L
            %i
            curEpoch = cellData.epochs(epochInd(i));
            
            %'MovingBget spike times (in units of seconds from startTime
            spikeTimes = curEpoch.getSpikes(ip.Results.DeviceName);
            spikeTimes = spikeTimes - stimStart;
            spikeTimes = spikeTimes / sampleRate;
            outputStruct.spikeCount_100ms_around_PSTH_peak.value(i) = length(spikeTimes(spikeTimes>=minTime & spikeTimes<maxTime));
        end
    end
    
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

%PSTH smoothing and suppression detection
baselineMean = mean(outputStruct.baselineRate.value);
baselineRateThres = 4; %we need at least this baseline (Hz) to calculate a suppression
if baselineMean > baselineRateThres
    smoothWin = 20; %points, sliding window
    suppressionThreshold = 0.5; %fraction of mean
    suppressionMinThreshold = .25; %fraction of mean
    psth_smooth = smooth(psth,smoothWin);
    ONSET_ind = find(xvals>=0 & xvals < intervalEnd);
    ONSET_to_end_ind = find(xvals>=0);
    OFFSET_ind = find(xvals>=intervalEnd);
    ONSET_part = psth_smooth(ONSET_ind);
    ONSET_to_end_part = psth_smooth(ONSET_to_end_ind);
    OFFSET_part = psth_smooth(OFFSET_ind);
    %ONSET
    suppFound = 0;
    temp = find(ONSET_part<baselineMean*suppressionThreshold, 1);
    if ~isempty(temp)
        ONSET_suppression_start_ind = temp;
        ONSET_suppression_start = xvals(ONSET_ind(ONSET_suppression_start_ind));
        suppFound = 1;
    end
    temp = getThresCross(ONSET_to_end_part, baselineMean*suppressionThreshold, 1);
    if suppFound
        if ~isempty(temp)
            [minVal, minLoc] = min(ONSET_part); %first min
            if minVal<suppressionMinThreshold*baselineMean
                thresInd = find(temp>minLoc);
                if ~isempty(thresInd)
                    ONSET_suppression_end_ind = temp(thresInd(1));
                    ONSET_suppression_end = xvals(ONSET_to_end_ind(ONSET_suppression_end_ind));
                    suppFound = suppFound + 1;
                end
            end
        end
    end
    if suppFound == 2 %both onset and offset found
        outputStruct.ONSETsuppressionTime.value = ONSET_suppression_end - ONSET_suppression_start;
        outputStruct.ONSETsuppressedSpikes.value = baselineMean * outputStruct.ONSETsuppressionTime.value - mean(ONSET_to_end_part(ONSET_suppression_start_ind:ONSET_suppression_end_ind));
    end
    
    %OFFSET ( !!!not fixed to be like onset yet!!! )
    suppFound = 0;
    temp = find(OFFSET_part<baselineMean*suppressionThreshold, 1);
    if ~isempty(temp)
        OFFSET_suppression_start_ind = temp(1);
        OFFSET_suppression_start = xvals(OFFSET_ind(OFFSET_suppression_start_ind));
        suppFound = 1;
    end
    if suppFound
        temp = getThresCross(OFFSET_part, baselineMean*suppressionThreshold, 1);
        if ~isempty(temp) && temp(1) > OFFSET_suppression_start_ind
            OFFSET_suppression_end_ind = temp(1);
        else
            OFFSET_suppression_end_ind = length(OFFSET_ind); %suppressed until the end of recording
        end
        OFFSET_suppression_end = xvals(OFFSET_ind(OFFSET_suppression_end_ind));
        outputStruct.OFFSETsuppressionTime.value = OFFSET_suppression_end - OFFSET_suppression_start;
        outputStruct.OFFSETsuppressedSpikes.value = baselineMean * outputStruct.OFFSETsuppressionTime.value - mean(OFFSET_part(OFFSET_suppression_start_ind:OFFSET_suppression_end_ind));
    end
    
end

end


