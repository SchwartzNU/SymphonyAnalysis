% Model generator for RG cells.

% function returnStruct = noiseFilter(cellData, epochIndices, model)




%% Generate model parameters

stimulus = stimulusAllEpochs;
stimulusFiltered = filtfilt(stimFilter, stimulus);
response = responseAllEpochs;
modelFitIndices = repeatMarkerFull;

% Set parameters of fits
numSpatialDimensions = size(stimulus,2);
tent_basis_spacing = 1; % represent stimulus filters using tent-bases with this spacing (in up-sampled time units)
timeCutoff = 0.3;
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

nim = NIM(params_stim, [], [], 'spkNL', 'rectpow');


numAdditiveSubunits = 4;

for si = 1:numAdditiveSubunits
    nim = nim.add_subunits('rectlin', 1); % , 'init_filts', {filterInits{si}}
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

nonpar_reg = 100; % set regularization value
useNonparametricSubunitNonlinearity = true;
enforceMonotonicSubunitNonlinearity = true; % slow and unreliable
if useNonparametricSubunitNonlinearity
    nim = nim.init_nonpar_NLs( Xstim, 'lambda_nld2', nonpar_reg, 'NLmon', enforceMonotonicSubunitNonlinearity);
end
    
% use this later:
% nim = nim.init_spkhist( 20, 'doubling_time', 5 );
tic
numFittingLoops = 10;
nim = nim.set_reg_params('d2t', 200);
nim = nim.set_reg_params('d2x', 0);

r2 = 0;
for fi = 1:numFittingLoops
    fprintf('Fit loop %g of %g \n', fi, numFittingLoops);
    nim = nim.fit_filters( response, Xstim, 'silent', 1, 'fit_offsets', 1);
    if useNonparametricSubunitNonlinearity
        nim = nim.fit_upstreamNLs( response, Xstim, 'silent', 1);
    end
    nim = nim.fit_spkNL(response, Xstim, 'silent', 1);
    [ll, responsePrediction, mod_internals] = nim.eval_model(response, Xstim);
    
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


%% Display model components
colorsByColor = [0, .7, .0;
                .3, 0, .9];

figure(199);clf;
numSubunits = length(nim.subunits);

handles = tight_subplot(numSubunits,1, .05);

% subunit filters

filterTime = (1:nLags)-1;
filterTime = filterTime * stim_dt;
h = [];
for si = 1:numSubunits
    axes(handles(si));
    h = [];
    filters = reshape(nim.subunits(si).filtK, [], numSpatialDimensions);
    for fi = 1:size(filters,2)
        c = colorsByColor(mod(fi-1, 2)+1,:);
        if fi >= 3 % surround dashed
            style = '--';
        else
            style = '-';
        end
        h(fi) = plot(filterTime, filters(:,fi), 'LineWidth',2, 'LineStyle',style, 'Color', c);
        hold on
        line([0,max(filterTime)],[0,0],'Color','k', 'LineStyle',':');

    end
    legend(h(:), legString)
    if si == 1
        title('subunit linear filters')
    end
end
% legString = cellfun(@num2str, num2cell(1:10), 'UniformOutput', 0);
% legend({'center green','center uv','surround green','surround uv'})
linkaxes(handles)

figure(200);clf;
handles = tight_subplot(numSubunits,1, .05);

% Subunit nonlinearity

for si=1:numSubunits
    axes(handles(si));
    yyaxis left
    
    % input histogram
    histogram(subunitOutputL(:,si), 'DisplayStyle','stairs', 'Normalization', 'Probability','EdgeColor','r')
%     ,'EdgeColor', colorsBySubunit(si,:)
    hold on
    
    % output histogram
    histogram(nim.subunits(si).weight * subunitOutputLN(:,si), 'DisplayStyle','stairs', 'Normalization','Probability', 'EdgeColor','g');

    % nonlinearity
    subunit = nim.subunits(si);
    gendist_x = xlim();
    if strcmp(subunit.NLtype, 'nonpar')          
        x = subunit.NLnonpar.TBx; y = subunit.NLnonpar.TBy;        
    else
        x = gendist_x; y = subunit.apply_NL(x);
    end
    
    yyaxis right
    plot(x, y, '-', 'LineWidth',1) %, 'Color', colorsBySubunit(si,:)
    
    
    legend({'input','output','nonlinearity'}, 'Location', 'NorthWest')
    
    hold on
    line(xlim(),[0,0],'Color','k', 'LineStyle',':')
    line([0,0], ylim(),'Color','k', 'LineStyle',':')    
    
    if si == 1
        title('subunit generator & output nonlinearity')
    end
end


% Subunit outputs
for si = 1:numSubunits
    axes(handles(si))
%    , 'EdgeColor', colorsBySubunit(si,:)
   hold on
end
legend(legString)
title('subunit output (after weights)')
hold on



% Overall output nonlinearity
figure(203);clf;
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
plot(t, stimulusFiltered)
grid on
legend(legString)

axes(handles(2))
for si = 1:numSubunits
    plot(t, nim.subunits(si).weight * subunitOutputLN(:,si)/3)%, 'Color', colorsBySubunit(si,:))
    hold on
end
legend('sub 1','sub 2','sub 3','sub 4','sub 5','sub 6')
% legend('sub 1 out weighted (ON+)','sub 2 out weighted (ON-)','sub 3 out weighted (OFF)')
grid on

% response
axes(handles(3));
plot(t, response, 'g')
hold on
% plot(t, generatingFunction, 'b:')
plot(t, responsePrediction, 'r')
ylim('auto')
grid on
legend('response','prediction')

linkaxes(handles, 'x')
xlim([1, 20])

pan xon

% step response
figure(205);clf;
handles = tight_subplot(2,2, .1);
stepStartTime = 0.5;
stepEndTime = 1.0;
offsetTime = 1.5;
titles = {'center green','center uv','surround green','surround uv'};

t = (0:1/updateRate:3)';
for ci = 1:4
    artificialStim = zeros(size(t,1), 4);
    artificialStim(t >= stepStartTime & t <= stepEndTime, ci) = 1;
    artificialStim(t - offsetTime >= stepStartTime & t - offsetTime <= stepEndTime, ci) = -1;
    artXstim = NIM.create_time_embedding(artificialStim, params_stim);
    [~, artResponsePrediction_s] = nim.eval_model([], artXstim);
    
    axes(handles(ci))
    plot(t, artificialStim);
    
    hold on
    plot(t, artResponsePrediction_s)
%     legend('stimulus','response')
    title(titles{ci})
end






