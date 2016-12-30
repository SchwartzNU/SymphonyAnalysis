
% function returnStruct = noiseFilter(cellData, epochIndices, model)

%% load data
% load cellData/102816Ac3.mat
% epochIndices = [311 314 317];

% load cellData/102516Ac2.mat
% epochIndices = [167];

% load cellData/110216Ac19.mat
% epochIndices = 218:251;

% spiking WFDS
% load cellData/121616Ac2.mat 
% epochIndices = 133:135;

% spiking On Off DS
% load cellData/121616Ac4.mat 
% epochIndices = 30;

% WC on wfds
load cellData/121616Ac7.mat 
epochIndices = 63;

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
stimFilter = designfilt('lowpassfir','PassbandFrequency',6, ...          
    'StopbandFrequency',8,'PassbandRipple',0.5, 'SampleRate', frameRate, ...     
    'StopbandAttenuation',65,'DesignMethod','kaiserwin');


%% generate responses and stims, then glue them all together
responseFull = [];
stimulusFull = [];
repeatMarkerFull = [];

averageRepeatSeedEpochs = true;

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
        spikeMode = true;
    else
        spikeMode = false;
        
        responseRaw = epoch.getData('Amplifier_Ch1');        
        response = responseRaw * sign(mean(responseRaw));
        response = response / max(response);
        response = response - mean(response);
        % response = response + 2;
        %     response = zscore(response);
        response = resample(response, frameRate, sampleRate);

        m = min([length(stimulus), length(response)]);
        response = response(1:m);
        stimulus = stimulus(1:m);
%         while length(stimulus) < length(response)
%             stimulus  = [stimulus; ml];
%         end
    end

    %% compose data together

    assert(all(size(stimulus) == size(response)))
    repeatMarker = isRepeatSeed * ones(size(stimulus));

    if averageRepeatSeedEpochs
        
        stimulusFull = [stimulus, stimulusFull];
        responseFull = [response, responseFull];
        repeatMarkerFull = [repeatMarker, repeatMarkerFull];
    else
        
        stimulusFull = [stimulus; stimulusFull];
        responseFull = [response; responseFull];
        repeatMarkerFull = [repeatMarker; repeatMarkerFull];
    end

end

if averageRepeatSeedEpochs
    stimulusFull = mean(stimulusFull, 2);
    responseFull = mean(responseFull, 2);
    repeatMarkerFull = mean(repeatMarkerFull, 2);
end


figure(6);clf;
handles = tight_subplot(3,1);
plot(handles(1), stimulusFull)
plot(handles(2), responseFull)
plot(handles(3), repeatMarkerFull)


%% Generate model parameters

stimulus = stimulusFull;
stimulusFiltered = filtfilt(stimFilter, stimulus);
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
% use a saved filter to get things looking right at the start (avoid inversions)
% nim = NIM(params_stim, NL_types, subunit_signs, 'd2t', lambda_d2t, 'init_filts', {savedFilter});
nim = NIM(params_stim, NL_types, subunit_signs, 'd2t', lambda_d2t);

% Fit model filters
nim = nim.fit_filters(response, Xstim, 'silent', 1 );

% add subunit starting with a delayed copy of the first
% delayed_filt = nim.shift_mat_zpad( nim.subunits(1).filtK, 4 );
% nim = nim.add_subunits( {'rectlin'}, -1, 'init_filts', {delayed_filt} );
% nim = nim.fit_filters(response, Xstim);

% add subunit as an OFF filter
% flipped_filt = -1 * nim.subunits(1).filtK;
% nim = nim.add_subunits( {'rectlin'}, 1, 'init_filts', {flipped_filt} );
% nim = nim.fit_filters(response, Xstim);

% fit upstream nonlinearities
nonpar_reg = 20; % set regularization value
nim = nim.init_nonpar_NLs( Xstim, 'lambda_nld2', nonpar_reg );
nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1 );

% Do another iteration of fitting filters and upstream NLs
nim = nim.fit_filters( response, Xstim, 'silent', 1 );
nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1 );

% nim = nim.init_spkhist( 20, 'doubling_time', 5 );

% if spikeMode
%     nim = nim.fit_spkNL(response, Xstim);
% end

% plot for each epoch in a row


[ll, responsePrediction_s, mod_internals] = nim.eval_model(response, Xstim);
fprintf('Log likelihood: %g\n', -1*ll);

generatingFunction = mod_internals.G;
subunitOutputComplete = mod_internals.fgint;
subunitOutputPrimary = mod_internals.gint;


%

figure(200);clf;
handles = tight_subplot(2,2);
numSubunits = length(nim.subunits);

% filter
axes(handles(1));
for i = 1:numSubunits
    f = nim.subunits(i).filtK;
    plot(f);
    hold on
end
legend('1','2')
title('filters')

axes(handles(2));
title('subunit nonlinearities')
hold on
for si=1:numSubunits
    nim.subunits(si).display_NL(subunitOutputPrimary(:,si))
end

axes(handles(3))
title('spiking nonlinearity');
nim.display_spkNL(generatingFunction);

% notes for LN:
% generate nonlinearity using repeated epochs
% get mean filter from the single run epochs



%% Display time signals

figure(201);clf;
warning('off', 'MATLAB:legend:IgnoringExtraEntries')
% handles = tight_subplot(2,2);

% stimulus
% axes(handles(1));
t = linspace(0, length(stimulus) / frameRate, length(stimulus));
% plot(t, stimulus)
hold on
plot(t, stimulusFiltered * 3, 'LineWidth',3)

% response
% axes(handles(2));
plot(t, response)
hold on
% plot(t, responsePrediction)
plot(t, responsePrediction_s)

plot(t, subunitOutputComplete/3, '--')
legend('stim filtered','response','prediction spiking nl', 's1','s2','s3')
hold off
title('response')

return

