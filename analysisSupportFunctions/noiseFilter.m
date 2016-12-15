
function returnStruct = noiseFilter(cellData, epochIndices, model)

    returnStruct = struct();

    % organize epochs by seed: repeats and nonrepeats
    % probably this'd be a quarter this length in Python, god help me MathWorks
    numberOfEpochs = length(epochIndices);
    seedByEpoch = [];
    for ei=1:numberOfEpochs

        epoch = cellData.epochs(epochIndices(ei));
        centerNoiseSeed = epoch.get('centerNoiseSeed');
        stimulusAreaMode = epoch.get('currentStimulus');
        
        seedByEpoch(ei) = centerNoiseSeed;
    end
    
    uniqueSeeds = unique(seedByEpoch);
    uniqueSeedCounts = [];
    for ui = 1:length(uniqueSeeds)
        uniqueSeedCounts(ui) = sum(seedByEpoch == uniqueSeeds(ui));
    end
    
    repeatSeeds = uniqueSeeds(uniqueSeedCounts > 1);
    if ~isempty(repeatSeeds)
        repeatSeed = repeatSeeds(1);
    end
    singleSeeds = uniqueSeeds(uniqueSeedCounts == 1);
    repeatRunEpochIndices = epochIndices(seedByEpoch == repeatSeed);
    
    singleRunEpochIndices = [];
    for ei = 1:numberOfEpochs
        if any(singleSeeds == seedByEpoch(ei))
            singleRunEpochIndices(end+1) = epochIndices(ei);
        end
    end
    
    % generate filter for each single-run epoch
    figure(200);clf;
    numberOfEpochs = length(singleRunEpochIndices);
    handles = tight_subplot(numberOfEpochs, 3);

    frameRate = cellData.epochs(singleRunEpochIndices(1)).get('patternRate');
    stimFilter = designfilt('lowpassfir','PassbandFrequency',8, ...          
        'StopbandFrequency',13,'PassbandRipple',0.5, 'SampleRate', frameRate, ...     
        'StopbandAttenuation',65,'DesignMethod','kaiserwin');    
    
    for ei=1:numberOfEpochs

        epoch = cellData.epochs(singleRunEpochIndices(ei));
        centerNoiseSeed = epoch.get('centerNoiseSeed');
        stimulusAreaMode = epoch.get('currentStimulus');

        if ~strcmp(stimulusAreaMode, 'Center')
            return
        end

        fprintf('Starting on epoch %g w/ center seed %g\n', ei, centerNoiseSeed);

        % generate response
        sampleRate = epoch.get('sampleRate');
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
    
        stimulusFiltered = filtfilt(stimFilter, stimulus);
        
        if strcmp(model, 'LN filter')

            %% Generate neuron linear filter using FFT
            updateRate = frameRate/epoch.get('frameDwell');
            freqCutoff = 30;  
            filterFFT = fft(response) ./ fft(stimulus);
            freqcutoff_adjusted = round(freqCutoff/(updateRate/length(stimulus))) ; % this adjusts the freq cutoff for the length
            filterFFT(:,1+freqcutoff_adjusted:length(stimulus)-freqcutoff_adjusted) = 0 ;     
            filterT = real(ifft(filterFFT));

            timeCutoff = 0.5;
            timeCutoffCount = round(timeCutoff * updateRate);
            filterT = filterT(1:timeCutoffCount);
            
            
        elseif strcmp(model, 'NIM LN')
            
            % Set parameters of fits
            up_samp_fac = 1; % temporal up-sampling factor applied to stimulus 
            tent_basis_spacing = 1; % represent stimulus filters using tent-bases with this spacing (in up-sampled time units)
            timeCutoff = 0.5;
            updateRate = frameRate/epoch.get('frameDwell');
            nLags = round(timeCutoff * updateRate);
            
            % Create structure with parameters using static NIM function
            params_stim = NIM.create_stim_params([nLags 1 1], 'stim_dt', 1/frameRate, 'upsampling', up_samp_fac, 'tent_spacing', tent_basis_spacing );

            % Create T x nLags 'design matrix' representing the relevant stimulus history at each time point
            Xstim = NIM.create_time_embedding(stimulus', params_stim);

            %% Fit a single-filter LN model (without cross-validation)
            NL_types = {'lin'}; % define subunit as linear (note requires cell array of strings)
            subunit_signs = [1]; % determines whether input is exc or sup (mult by +1 in the linear case)

            % Set initial regularization as second temporal derivative of filter
            lambda_d2t = 1;

            % Initialize NIM 'object' (use 'help NIM.NIM' for more details about the contructor 
            LN = NIM(params_stim, NL_types, subunit_signs, 'd2t', lambda_d2t);

            % Fit model filters
            LN = LN.fit_filters(response', Xstim);
            
            filterT = LN.subunits(1).filtK;

        end

       
        %% plot for each epoch in a row
        % stimulus
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

        % response
        axes(handles((ei-1) * 3 + 2));
        plot(response)
        if ei == 1
            title('response')
        end    

        % filter
        axes(handles((ei-1) * 3 + 3));
        plot(filterT(1:end))
        if ei == 1
            title('filter')
        end

%         linkaxes(handles((ei-1) * 3 + [1,2]))
    
        returnStruct.filtersByEpoch{ei,1} = filterT;
        returnStruct.timeByEpoch{ei,1} = t;
        
    end
    
    % generate nonlinearity using repeated epochs
    % get mean filter from the single run epochs
    
    allFilters = cell2mat(returnStruct.filtersByEpoch);
    meanFilter = mean(allFilters);
    repeatedStimulus = [];
    allResponses = [];
    
    for ei = 1:length(repeatRunEpochIndices)
        epoch = cellData.epochs(repeatRunEpochIndices(ei));
        centerNoiseSeed = epoch.get('centerNoiseSeed');
        stimulusAreaMode = epoch.get('currentStimulus');

        if ~strcmp(stimulusAreaMode, 'Center')
            return
        end
        
        response = epoch.getData('Amplifier_Ch1')';
        response = response * sign(mean(response));
        response = response - mean(response);
    %     response = zscore(response);
        response = resample(response, frameRate, sampleRate);
        allResponses(ei,:) = response;
        
        
        if ei == 1
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
            repeatedStimulus = stimulus;
        end
    end
    
    meanResponse = mean(allResponses);
    
    %% generate prediction
    responsePrediction = conv(meanFilter, repeatedStimulus);
    responsePrediction = responsePrediction(1:end-length(filterT)+1);
%         responsePrediction = responsePrediction(1:length(response));

    % solve nonlinearity
    inpt = responsePrediction;
    inpt = inpt - mean(inpt);
    inpt = inpt / max(abs(inpt));
    responsePrediction = inpt;
    out = meanResponse;
    out = out - mean(out);
    out = out / max(abs(out));
    meanResponse = out;

    [~,i] = sort(inpt);
    inpt = inpt(i);
    out = out(i);
    
    figure(10); clf;
    plot(inpt, out, '.')
    hold on
    bucketLen = floor(length(out) / 20);
    numbuckets = ceil(length(out) / bucketLen);

    nonlinInput = [];
    nonlinOutput = [];
    for bi = 1:numbuckets
        r = (bi-1) * bucketLen + (1:bucketLen);
        nonlinInput(bi) = mean(inpt(r));
        nonlinOutput(bi) = mean(out(r));
    end

    plot(nonlinInput,nonlinOutput,'LineWidth',3);


    %% Generate LN prediction

    figure(15)
    plot(meanFilter)
    
    responsePredictionNonlin = interp1(nonlinInput,nonlinOutput, responsePrediction, 'linear', 'extrap');

    figure(20);clf;
    plot(meanResponse)
    hold on
    plot(responsePrediction)
    plot(responsePredictionNonlin)
%     plot(repeatedStimulus)
%     plot(allResponses')
    legend('mean response','prediction (lin)','prediction (nonlin)')
end


