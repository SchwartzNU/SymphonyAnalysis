

epochIndices = [311 314 317];
numberOfEpochs = length(epochIndices);
uifig = figure(200);clf;clc;

handles = tight_subplot(numberOfEpochs, 3);

% loop through all epochs and generate a linear filter for each
for ei=1:numberOfEpochs
    
    epoch = cellData.epochs(epochIndices(ei));
    centerNoiseSeed = epoch.get('centerNoiseSeed');
    stimulusAreaMode = epoch.get('currentStimulus');
    
    if ~strcmp(stimulusAreaMode, 'Center')
        return
    end
    
    fprintf('Starting on epoch %g w/ center seed %g\n', ei, centerNoiseSeed);
    
    sampleRate = epoch.get('sampleRate');
    response = epoch.getData('Amplifier_Ch1');
    response = response * sign(mean(response));
    response = response - median(response);
    
    centerNoiseStream = RandStream('mt19937ar', 'Seed', centerNoiseSeed);
    stimulus = [];
    
    displayFrameRate = 60;
    %                 chunkLen = epoch.get('frameDwell') / displayFrameRate;
    stimFrames = round(displayFrameRate * (epoch.get('stimTime')/1e3));
    for ii = 1:floor(stimFrames/epoch.get('frameDwell'))
        
        stimulus(ii) = centerNoiseStream.randn;
    end
    ml = epoch.get('meanLevel');
    contrast = 1; %epoch.get('currentContrast')
    stimulus = ml + contrast * ml * stimulus;
    stimulus(stimulus < 0) = 0;
    stimulus(stimulus > 1) = 1;
    
    axes(handles((ei-1) * 3 + 1));
    plot(stimulus)
    
    axes(handles((ei-1) * 3 + 2));
    plot(response)
    % regenerate stimulus
    
    %                 t =
    drawnow
    
end