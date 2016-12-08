
load cellData/102816Ac3.mat
epochIndices = [311 314 317];

% load cellData/102516Ac2.mat
% epochIndices = [167];

numberOfEpochs = length(epochIndices);
uifig = figure(200);clf;clc;

handles = tight_subplot(numberOfEpochs, 3);

% loop through all epochs and generate a linear filter for each
allStimuli = [];
allFilters = [];

for ei=1:numberOfEpochs
    
    epoch = cellData.epochs(epochIndices(ei));
    centerNoiseSeed = epoch.get('centerNoiseSeed');
    stimulusAreaMode = epoch.get('currentStimulus');
    
    if ~strcmp(stimulusAreaMode, 'Center')
        return
    end
    
    fprintf('Starting on epoch %g w/ center seed %g\n', ei, centerNoiseSeed);
    
    % generate response
    sampleRate = epoch.get('sampleRate');
    frameRate = epoch.get('patternRate');
    response = epoch.getData('Amplifier_Ch1')';
    response = response * sign(mean(response));
    response = response - mean(response);
%     response = zscore(response);
    response = resample(response, frameRate, sampleRate);
    
    %% Generate stimulus
    
    centerNoiseStream = RandStream('mt19937ar', 'Seed', centerNoiseSeed);
    stimulus = [];
    
    %                 chunkLen = epoch.get('frameDwell') / displayFrameRate;
    preFrames = round(frameRate * (epoch.get('preTime')/1e3));
    stimFrames = round(frameRate * (epoch.get('stimTime')/1e3));
    stimulus(1:preFrames) = zeros(1, preFrames);
    for fi = preFrames+1:floor(stimFrames/epoch.get('frameDwell'))
        stimulus(fi) = centerNoiseStream.randn;
    end
    ml = epoch.get('meanLevel');
    contrast = 1; %epoch.get('currentContrast')
    stimulus = ml + contrast * ml * stimulus;
    
    while length(stimulus) < length(response)
        stimulus  = [stimulus, ml];
    end
    
    stimulus(stimulus < 0) = 0;
    stimulus(stimulus > 1) = 1;
%     stimulus = smooth(stimulus, 3);
    stimFilter = designfilt('lowpassfir','PassbandFrequency',8, ...          
        'StopbandFrequency',13,'PassbandRipple',0.5, 'SampleRate', frameRate, ...     
        'StopbandAttenuation',65,'DesignMethod','kaiserwin');
    stimulusFiltered = filtfilt(stimFilter, stimulus);
    
    %% plot for each epoch in a row
    axes(handles((ei-1) * 3 + 1));
    t = linspace(0, length(stimulus) / frameRate, length(stimulus));
    plot(t, stimulus)
    hold on
    plot(t, stimulusFiltered, 'LineWidth',2)
    hold off
    if ei == 1
        title('stimulus')
    end
    ylabel(sprintf('epoch: %g',ei))
    
    axes(handles((ei-1) * 3 + 2));
    plot(t, response ./ max(response))
    if ei == 1
        title('response')
    end    
    updateRate = frameRate/epoch.get('frameDwell');
%     freqCutoffFraction = 0.3;
    filterT = getLinearFilterOnline(stimulus, response, updateRate, 30);
    filterFFT = fft(response) ./ fft(stimulus);
    filterT = real(ifft(filterFFT));
    
    allFilters(ei,:) = filterT;
    
    axes(handles((ei-1) * 3 + 3));
    plot(filterT(1:end))
    if ei == 1
        title('filter')
    end
    
    linkaxes(handles((ei-1) * 3 + [1,2]))
    
    
end

figure(201);clf;
% plot(t, allFilters);
% hold on
mn = mean(allFilters);
se = std(allFilters)/sqrt(numberOfEpochs);
plot(t, [mn; mn+se; mn-se], 'LineWidth', 1)
% hold off
title('Filter mean and sem')


function [LinearFilter] = getLinearFilterOnline(stimulus, response, samplerate, freqcutoff)

% this function will find the linear filter that changes row vector "stimulus" 
% into a set of "responses" in rows.  "samplerate" and "freqcuttoff" 
% (which should be the highest frequency in the signal) should be in HZ.

% The linear filter is a cc normalized by the power spectrum of the signal
% JC 3/31/08
%MHT 080814

%for rows as trials
FilterFft = mean((fft(response,[],2).*conj(fft(stimulus,[],2))),1)./mean(fft(stimulus,[],2).*conj(fft(stimulus,[],2)),1) ;

freqcutoff_adjusted = round(freqcutoff/(samplerate/length(stimulus))) ; % this adjusts the freq cutoff for the length
FilterFft(:,1+freqcutoff_adjusted:length(stimulus)-freqcutoff_adjusted) = 0 ; 

LinearFilter = real(ifft(FilterFft)) ;

end