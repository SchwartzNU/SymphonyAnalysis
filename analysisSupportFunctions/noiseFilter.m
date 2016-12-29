
% function returnStruct = noiseFilter(cellData, epochIndices, model)

%% load data
% load cellData/102816Ac3.mat
% epochIndices = [311 314 317];

% load cellData/102516Ac2.mat
% epochIndices = [167];

% load cellData/110216Ac19.mat
% epochIndices = 218:251;

% spiking WFDS
load cellData/121616Ac2.mat 
epochIndices = 133:135;


returnStruct = struct();

%% organize epochs

centerEpochs = [];
numberOfEpochs = length(epochIndices);
for ei=1:numberOfEpochs

    epoch = cellData.epochs(epochIndices(ei));
    centerNoiseSeed = epoch.get('centerNoiseSeed');
    stimulusAreaMode = epoch.get('currentStimulus');

    if strcmp(stimulusAreaMode, 'Center')
        centerEpochs(end+1) = epochIndices(ei);
    end
end
epochIndices = centerEpochs;

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


frameRate = cellData.epochs(epochIndices(1)).get('patternRate');
stimFilter = designfilt('lowpassfir','PassbandFrequency',8, ...          
    'StopbandFrequency',13,'PassbandRipple',0.5, 'SampleRate', frameRate, ...     
    'StopbandAttenuation',65,'DesignMethod','kaiserwin');    


%% generate responses and stims, then glue them all together
responseFull = [];
stimulusFull = [];
repeatMarkerFull = [];
for ei=1:numberOfEpochs

    epoch = cellData.epochs(epochIndices(ei));
    centerNoiseSeed = epoch.get('centerNoiseSeed');
    stimulusAreaMode = epoch.get('currentStimulus');
    isRepeatSeed = any(centerNoiseSeed == repeatSeeds);

    if ~strcmp(stimulusAreaMode, 'Center')
        return
    end

    fprintf('Starting on epoch %g w/ center seed %g\n', ei, centerNoiseSeed);

    %% Generate stimulus

    centerNoiseStream = RandStream('mt19937ar', 'Seed', centerNoiseSeed);
    stimulus = [];

    %                 chunkLen = epoch.get('frameDwell') / displayFrameRate;
    preFrames = round(frameRate * (epoch.get('preTime')/1e3));
    stimFrames = round(frameRate * (epoch.get('stimTime')/1e3));
    stimulus(1:preFrames, 1) = zeros(preFrames, 1);
    for fi = preFrames+1:floor(stimFrames/epoch.get('frameDwell'))
        stimulus(fi, 1) = centerNoiseStream.randn;
    end
    ml = epoch.get('meanLevel');
    contrast = 1; %epoch.get('currentContrast')
    stimulus = ml + contrast * ml * stimulus;

    stimulus(stimulus < 0) = 0;
    stimulus(stimulus > ml * 2) = ml * 2;
    stimulus(stimulus > 1) = 1;
%     stimulus = smooth(stimulus, 3);

%         stimulusFiltered = filtfilt(stimFilter, stimulus);

    %% generate response
    sampleRate = epoch.get('sampleRate');

    if strcmp(epoch.get('ampMode'), 'Cell attached')
        spikeTimes = epoch.get('spikes_ch1') / sampleRate;
        response = NIM.Spks2Robs(spikeTimes, 1/frameRate, size(stimulus,1) );
    else
        responseRaw = epoch.getData('Amplifier_Ch1');        
        response = responseRaw * sign(mean(responseRaw));
        % response = response / max(response);
        response = response - mean(response);
        % response = response + 2;
        %     response = zscore(response);
        % response = resample(response, frameRate, sampleRate);

        while length(stimulus) < length(response)
            stimulus  = [stimulus; ml];
        end    
    end

    %% compose data together

    assert(all(size(stimulus) == size(response)))
    repeatMarker = isRepeatSeed * ones(size(stimulus));

    stimulusFull = [stimulus; stimulusFull];
    responseFull = [response; responseFull];
    repeatMarkerFull = [repeatMarker; repeatMarkerFull];

end

figure(6);clf;
handles = tight_subplot(3,1);
plot(handles(1), stimulusFull)
plot(handles(2), responseFull)
plot(handles(3), repeatMarkerFull)


%% Generate model parameters

stimulus = stimulusFull;
response = responseFull;
modelFitIndices = repeatMarkerFull;

% Set parameters of fits
up_samp_fac = 1; % temporal up-sampling factor applied to stimulus 
tent_basis_spacing = 1; % represent stimulus filters using tent-bases with this spacing (in up-sampled time units)
timeCutoff = 0.5;
updateRate = frameRate/epoch.get('frameDwell');
nLags = round(timeCutoff * updateRate);

% Create structure with parameters using static NIM function
params_stim = NIM.create_stim_params([nLags 1 1], 'stim_dt', 1/frameRate);

% Create T x nLags 'design matrix' representing the relevant stimulus history at each time point
Xstim = NIM.create_time_embedding(stimulus, params_stim);

%% Fit a single-filter LN model (without cross-validation)
NL_types = {'rectlin'}; % define subunit as linear (note requires cell array of strings)
subunit_signs = [1]; % determines whether input is exc or sup (mult by +1 in the linear case)

% Set initial regularization as second temporal derivative of filter
lambda_d2t = 1;

% Initialize NIM 'object' (use 'help NIM.NIM' for more details about the contructor 
nim = NIM(params_stim, NL_types, subunit_signs, 'd2t', lambda_d2t);

% Fit model filters
nim = nim.fit_filters(response, Xstim);

% fit upstream nonlinearities
nonpar_reg = 20; % set regularization value
nim = nim.init_nonpar_NLs( Xstim, 'lambda_nld2', nonpar_reg );
nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1 );

% Do another iteration of fitting filters and upstream NLs
nim = nim.fit_filters( response, Xstim, 'silent', 1 );
nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1 );

nims = nim.fit_spkNL(response, Xstim);

% plot for each epoch in a row

[ll, responsePrediction, mod_internals] = nim.eval_model(response, Xstim);
ll

[ll_s, responsePrediction_s, mod_internals] = nims.eval_model(response, Xstim);
generatingFunction = mod_internals.G;
subunitOutputComplete = mod_internals.fgint;
subunitOutputPrimary = mod_internals.gint;


figure(200);clf;
numberOfEpochs = length(epochIndices);
handles = tight_subplot(2,2);

% stimulus
axes(handles(1));
t = linspace(0, length(stimulus) / frameRate, length(stimulus));
plot(t, stimulus)
% hold on
% plot(t, stimulusFiltered, 'LineWidth',2)
% hold off
title('stimulus')

% response
axes(handles(2));
plot(response)
hold on
plot(responsePrediction)
plot(responsePrediction_s)
legend('response','prediction','prediction spiking nl')
hold off
title('response')

% filter
axes(handles(3));
for i = 1:length(subunit_signs)
    f = nim.subunits(i).filtK;
    plot(f);
    hold on
end
legend('1','2','3')
title('filter')

axes(handles(4));
title('spiking nonlinearity');
nim.display_spkNL(generatingFunction);


% generate nonlinearity using repeated epochs
% get mean filter from the single run epochs

%% Do NIM NL fitting


return

%%
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


