% Model generator for RG cells.

% function returnStruct = noiseFilter(cellData, epochIndices, model)

%% load data
% load cellData/102816Ac3.mat
% epochIndices = 311:319;

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
    repeatRunEpochIndices = epochIndices(seedByEpoch == repeatSeed);
else
    repeatSeed = [];
    repeatRunEpochIndices = [];
end
singleSeeds = uniqueSeeds(uniqueSeedCounts == 1);

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

    % Generate stimulus

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

    % generate response
    sampleRate = epoch.get('sampleRate');

    if strcmp(epoch.get('ampMode'), 'Cell attached')
        spikeTimes = epoch.get('spikes_ch1') / sampleRate;
        response = NIM.Spks2Robs(spikeTimes, 1/frameRate, size(stimulus,1) );
        useOutputNonlinearity = true;
    else
        useOutputNonlinearity = false;
        
        responseRaw = epoch.getData('Amplifier_Ch1');        
        response = responseRaw * sign(mean(responseRaw));
        response = response / max(response);
%         response = response + 0.08*(max(response) - min(response));
        response = response - min(response);
        % response = response + 2;
        %     response = zscore(response);
        response = resample(response, frameRate, sampleRate);
        
        response(response < 0) = 0;

        m = min([length(stimulus), length(response)]);
        response = response(1:m);
        stimulus = stimulus(1:m);
%         while length(stimulus) < length(response)
%             stimulus  = [stimulus; ml];
%         end
    end

    % compose data together

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

%% Generate Model

% use a saved filter to get things looking right at the start (avoid inversions)
% nim = NIM(params_stim, NL_types, subunit_signs, 'd2t', lambda_d2t, 'init_filts', {savedFilter});

% doc on the regularization types:
% nld2 second derivative of tent basis coefs
% d2xt spatiotemporal laplacian
% d2x 2nd spatial deriv
% d2t 2nd temporal deriv
% l2 L2 on filter coefs
% l1 L1 on filter coefs

% doc on output nonlinearities
% {'lin','rectpow','exp','softplus','logistic'}

nim = NIM(params_stim, [], [], 'spkNL', 'softplus');
nim = nim.add_subunits('lin', 1);
nim = nim.set_reg_params('d2t', 10);

% add negative subunit starting with a delayed copy of the first
nim = nim.fit_filters( response, Xstim, 'silent', 1);
useDelayedCopy = true;
if useDelayedCopy
    nim = nim.fit_filters(response, Xstim, 'silent', 1 );
    delayed_filt = nim.shift_mat_zpad( nim.subunits(1).filtK, 4 );
    nim = nim.add_subunits( {'lin'}, -1, 'init_filts', {delayed_filt});
else
    nim = nim.add_subunits( {'lin'}, -1);
end

% add subunit as an OFF filter
% nim = nim.fit_filters( response, Xstim, 'silent', 1);
% flipped_filt = -1 * nim.subunits(1).filtK;
% nim = nim.add_subunits( {'rectlin'}, 1, 'init_filts', {flipped_filt} );
% nim = nim.fit_filters(response, Xstim, 'silent', 1);

% add subunit as an -OFF filter
% flipped_filt = -1 * nim.subunits(3).filtK;
% delayed_filt = nim.shift_mat_zpad( nim.subunits(1).filtK, 4 );
% nim = nim.add_subunits( {'rectlin'}, -1, 'init_filts', {flipped_filt} );
% nim = nim.fit_filters(response, Xstim, 'silent', 1);

% fit upstream nonlinearities

nonpar_reg = 20; % set regularization value
useNonparametricSubunitNonlinearity = false;
enforceMonotonicSubunitNonlinearity = false;
if useNonparametricSubunitNonlinearity
    nim = nim.init_nonpar_NLs( Xstim, 'lambda_nld2', nonpar_reg, 'NLmon', enforceMonotonicSubunitNonlinearity);
end

% use this later:
% nim = nim.init_spkhist( 20, 'doubling_time', 5 );

numFittingLoops = 2;

for fi = 1:numFittingLoops
    nim = nim.fit_filters( response, Xstim, 'silent', 1);
    
    if useNonparametricSubunitNonlinearity
        nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1);
    end
    
    nim = nim.fit_spkNL(response, Xstim, 'silent', 1);
    
    [ll, responsePrediction_s, mod_internals] = nim.eval_model(response, Xstim);
    r2 = 1-mean((response-responsePrediction_s).^2)/var(response);
end
fprintf('Log likelihood: %g R2: %g\n', -1*ll, r2);


generatingFunction = mod_internals.G;
subunitOutputLN = mod_internals.fgint;
subunitOutputL = mod_internals.gint;

%% Display model components
colorsBySubunit = [1,0,.5; 0,.5,1; 0,1,.9; 1,.3,0];

figure(200);clf;
handles = tight_subplot(2,2, .05);
numSubunits = length(nim.subunits);

% subunit filters
axes(handles(1));
filterTime = 1:nLags;
filterTime = (filterTime-1) / updateRate;
h = [];
for si = 1:numSubunits
    f = nim.subunits(si).filtK;
    h(si) = plot(filterTime, f, 'Color', colorsBySubunit(si,:));
    hold on
end
line([0,max(filterTime)],[0,0],'Color','k', 'LineStyle',':');
legString = cellfun(@num2str, num2cell(1:10), 'UniformOutput', 0);
legend(h, legString)
title('subunit linear filters')

% Subunit nonlinearity
axes(handles(2));
for si=1:numSubunits
    yyaxis left
    histogram(subunitOutputL(:,si), 'DisplayStyle','stairs','EdgeColor', colorsBySubunit(si,:), 'Normalization', 'Probability')
    hold on
    gendist_x = xlim();
    
    subunit = nim.subunits(si);
    if strcmp(subunit.NLtype, 'nonpar')          
        x = subunit.NLnonpar.TBx; y = subunit.NLnonpar.TBy;        
    else
        x = gendist_x; y = subunit.apply_NL(x);
    end
    yyaxis right
    plot(x, y, '-', 'Color', colorsBySubunit(si,:), 'LineWidth',1)
    hold on
    
end
yyaxis right
line(xlim(),[0,0],'Color','k', 'LineStyle',':')
line([0,0], ylim(),'Color','k', 'LineStyle',':')
title('subunit generator & output nonlinearity')

% Subunit outputs
axes(handles(3))
for si = 1:numSubunits
   histogram(nim.subunits(si).weight * subunitOutputLN(:,si), 'DisplayStyle','stairs', 'EdgeColor', colorsBySubunit(si,:), 'Normalization','Probability');
   hold on
end
legend(legString)
title('subunit output (after weights)')
hold on

% Overall output nonlinearity
axes(handles(4))
yyaxis left
title('overall output');
generatorOffset = nim.spkNL.theta;
histogram(generatingFunction + generatorOffset, 'DisplayStyle','stairs','EdgeColor','k', 'Normalization','Probability');
hold on
yticklabels([])

yyaxis right
x = linspace(min(generatingFunction + generatorOffset), max(generatingFunction + generatorOffset));
y = nim.apply_spkNL(x);
plot(x,y, 'r')
xticklabels('auto')

legend('generator + offset', 'output NL')


% notes for LN:
% generate nonlinearity using repeated epochs
% get mean filter from the single run epochs



% Display time signals

figure(201);clf;
warning('off', 'MATLAB:legend:IgnoringExtraEntries')
handles = tight_subplot(3,1,0, [.05,.01], .05);

% stimulus
axes(handles(1));
t = linspace(0, length(stimulus) / frameRate, length(stimulus));
plot(t, stimulusFiltered, 'Color','k')
grid on
legend('stim lowpass')

axes(handles(2))
for si = 1:numSubunits
    plot(t, nim.subunits(si).weight * subunitOutputLN(:,si)/3, 'Color', colorsBySubunit(si,:))
    hold on
end
legend('sub 1 out weighted (ON+)','sub 2 out weighted (ON-)','sub 3 out weighted (OFF)')
grid on

% response
axes(handles(3));
plot(t, response, 'g')
hold on
% plot(t, generatingFunction, 'b:')
plot(t, responsePrediction_s, 'r')
grid on
legend('response','prediction')

linkaxes(handles, 'x')
xlim([5,7])

pan xon

%% step response
stepStartTime = 0.5;
stepEndTime = 1.5;

t = (0:1/updateRate:3)';
artStim = zeros(size(t));
artStim(t >= stepStartTime & t <= stepEndTime) = 0.5;
artXstim = NIM.create_time_embedding(artStim, params_stim);

figure(205);clf;
plot(t, artStim);

hold on
[~, artResponsePrediction_s] = nim.eval_model([], artXstim);
plot(t, artResponsePrediction_s)

legend('stimulus','response')





