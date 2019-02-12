% Model generator for RG cells.

% function returnStruct = noiseFilter(cellData, epochIndices, model)




%% Generate model parameters

stimulus = stimulusAllEpochs;
stimulusFiltered = filtfilt(stimFilter, stimulus);
response = responseAllEpochs;
modelFitIndices = repeatMarkerFull;

% Set parameters of fits
numSpatialDimensions = size(stimulus,2);
tent_basis_spacing = 2; % represent stimulus filters using tent-bases with this spacing (in up-sampled time units)
timeCutoff = 0.25;
updateRate = frameRate;
stim_dt = tent_basis_spacing/frameRate;
nLags = round(timeCutoff / stim_dt);

% subunit starting filters
% filterTime = (1:nLags)-1;
% filterTime = filterTime * stim_dt;
% bump = zeros(size(filterTime));
% bump(filterTime >= 0 & filterTime < .05) = .1;
% % color/location channel, polarity
% starts = [2, 1; % center UV On
%           2, -1; % center UV Off
%           3, 1; % surround Green On
%           3, -1;]; % surround Green Off
% filterInits = {};
% for fi = 1:size(starts, 1)
%     filterInits{fi} = zeros(4, length(filterTime));
%     filterInits{fi}(starts(fi,1), :) = bump * starts(fi,2);
%     filterInits{fi} = filterInits{fi}(:);
%     filterInits{fi} = filterInits{fi} + randn(size(filterInits{fi}));
% end
%

% Create structure with parameters using static NIM function
params_stim = NIM.create_stim_params([nLags numSpatialDimensions 1], 'stim_dt', stim_dt);

% Create T x nLags 'design matrix' representing the relevant stimulus history at each time point
Xstim = NIM.create_time_embedding(stimulus, params_stim);

% Generate Model

% use a saved filter to get things looking right at the start (avoid inversions)
% nim = NIM(params_stim, NL_types, subunit_signs, 'd2t', lambda_d2t, 'init_filts', {savedFilter});

% doc on the regularization types:
% nld2 second derivative of tent basis coefs
% d2xt spatiotemporal laplacian
% d2x 2nd spatial deriv
% d2t 2nd temporal deriv
% l2 L2 on filter coefs
% l1 L1 on filter coefs

% Output nonlinearities
% {'lin','rectpow','exp','softplus','logistic'}

% Subunit nonlinearities
% {'lin','quad','rectlin','rectpow','softplus','exp','nonpar'}

r2MinimumThreshold = 0.2;
fitConvergenceThreshold = 0.01;
r2 = 0;

while r2 < r2MinimumThreshold


nim = NIM(params_stim, [], [], 'spkNL', 'exp');


numAdditiveSubunits = 1;
useSavedNimSubunitFilters = 0;

for si = 1:numAdditiveSubunits
    if ~useSavedNimSubunitFilters
        nim = nim.add_subunits('rectlin', 1); % , 'init_filts', {filterInits{si}}
    else
        nim = nim.add_subunits('rectlin', 1, 'init_filts', {savenim.subunits(si).filtK});
    end

end

% add negative subunit starting with a delayed copy of the first
% useDelayedCopy = true;
% if useDelayedCopy
%     nim = nim.fit_filters(response, Xstim, 'silent', 1);
%     delayed_filt = nim.shift_mat_zpad(nim.subunits(1).filtK, 4);
%     nim = nim.add_subunits( {'lin'}, -1, 'init_filts', {delayed_filt});
% else
%     nim = nim.add_subunits( {'lin'}, -1);
% end    

% add subunit as an OFF filter
% nim = nim.fit_filters( response, Xstim, 'silent', 1);
% flipped_filt = -1 * nim.subunits(1).filtK;
% nim = nim.add_subunits( {'lin'}, 1, 'init_filts', {flipped_filt} );
% nim = nim.fit_filters(response, Xstim, 'silent', 1);

% add subunit as an -OFF filter
% flipped_filt = -1 * nim.subunits(3).filtK;
% delayed_filt = nim.shift_mat_zpad( nim.subunits(1).filtK, 4 );
% nim = nim.add_subunits( {'rectlin'}, -1, 'init_filts', {flipped_filt} );
% nim = nim.fit_filters(response, Xstim, 'silent', 1);


% initial solve
nim = nim.fit_filters( response, Xstim, 'silent', 1);

% fit upstream nonlinearities

nonpar_reg = 1000; % set regularization value
useNonparametricSubunitNonlinearity = true;
enforceMonotonicSubunitNonlinearity = true;
if useNonparametricSubunitNonlinearity
    nim = nim.init_nonpar_NLs( Xstim, 'lambda_nld2', nonpar_reg, 'NLmon', enforceMonotonicSubunitNonlinearity);
end
    
% use this later:
% nim = nim.init_spkhist( 20, 'doubling_time', 5 );
tic
numFittingLoops = 2;
nim = nim.set_reg_params('d2t', 100);
nim = nim.set_reg_params('d2x', 100);

r2 = 0;
for fi = 1:numFittingLoops
    fprintf('Fit loop %g of %g \n', fi, numFittingLoops);
    try
        nim = nim.fit_filters( response, Xstim, 'silent', 1, 'fit_offsets', 1);
        if useNonparametricSubunitNonlinearity
            nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1);
        end
        nim = nim.fit_spkNL(response, Xstim, 'silent', 1);
        [ll, responsePrediction, mod_internals] = nim.eval_model(response, Xstim);
    catch
        break;
    end
    
    prev_r2 = r2;
    r2 = 1-mean((response-responsePrediction).^2)/var(response);
    fprintf('Log likelihood: %g R2: %g\n', -1*ll, r2);
    if r2 - prev_r2 < fitConvergenceThreshold
        break
    end
end

toc
end

generatingFunction = mod_internals.G;
subunitOutputLN = mod_internals.fgint;
subunitOutputL = mod_internals.gint;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
noiseFilter_spatial_displayModel