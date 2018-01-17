%% Display model components
colorsByColor = [0, .7, .0;
                .3, 0, .9];

figure(199);clf;
numSubunits = length(nim.subunits);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subunit filters
handles = tight_subplot(numSubunits,1, .05);

filterTime = (1:nLags)-1;
filterTime = filterTime * stim_dt;
h = [];
for si = 1:numSubunits
    axes(handles(si));
    h = [];
    filters = reshape(nim.subunits(si).filtK, [], numSpatialDimensions);
    for fi = 1:size(filters,2)
        c = colorsByColor(mod(fi-1, 2)+1,:);
        if numSpatialDimensions == 4 && fi >= 3 % surround dashed
            style = '--';
        else
            style = '-';
        end
        h(fi) = plot(filterTime, filters(:,fi), 'LineWidth',2, 'LineStyle',style, 'Color', c);

        hold on
        line([0,max(filterTime)],[0,0],'Color','k', 'LineStyle',':');
%         xlabel('time before output')
    end
    legend(h(:), locationNames)
    if si == 1
        title('subunit linear filters')
    end
end
% legString = cellfun(@num2str, num2cell(1:10), 'UniformOutput', 0);
% legend({'center green','center uv','surround green','surround uv'})
% linkaxes(handles)

%% filters in FFT
figure(209);clf;
handles = tight_subplot(numSubunits, 1, .05);


h = [];
for si = 1:numSubunits
    axes(handles(si));
    h = [];
    filters = reshape(nim.subunits(si).filtK, [], numSpatialDimensions);
    for fi = 1:size(filters,2)
        
        filtfft = abs(fft(filters(:,fi)));
        n = length(filters(:,fi));
        freqaxis = (0:n-1)*((1/stim_dt)/n);
        filtfft = filtfft(1:ceil(n/2));
        freqaxis = freqaxis(1:ceil(n/2));
        c = colorsByColor(mod(fi-1, 2)+1,:);
        if numSpatialDimensions == 4 && fi >= 3 % surround dashed
            style = '--';
        else
            style = '-';
        end
        h(fi) = plot(freqaxis, filtfft, 'LineWidth',2, 'LineStyle',style, 'Color', c);

        hold on
%         line([0,max(filterTime)],[0,0],'Color','k', 'LineStyle',':');
        xlabel('freq (Hz)')
    end
    legend(h(:), locationNames)
    if si == 1
        title('subunit filter FFT')
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subunit generator & output nonlinearity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(200);clf;
handles = tight_subplot(numSubunits,1, .05);

for si=1:numSubunits
    axes(handles(si));
    yyaxis left
    
    % input histogram
    histogram(subunitOutputL(:,si), 'DisplayStyle','stairs', 'Normalization', 'Probability','EdgeColor','r')
%     ,'EdgeColor', colorsBySubunit(si,:)
    hold on
    
    % output histogram
    histogram(nim.subunits(si).weight * subunitOutputLN(:,si), 'DisplayStyle','stairs', 'Normalization','Probability', 'EdgeColor','g');

    set(handles(si),'yscale','log')
    
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
    
%     xticks('auto')
    xticklabels('auto')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Display time signals

figure(201);clf;
warning('off', 'MATLAB:legend:IgnoringExtraEntries')
handles = tight_subplot(3,1,0, [.05,.01], .05);

% stimulus
axes(handles(1));
t = linspace(0, length(stimulus) / frameRate, length(stimulus));
for fi = 1:size(stimulusFiltered,2)
    if numSpatialDimensions == 4
        c = colorsByColor(mod(fi-1, 2)+1,:);
        if fi >= 3 % surround dashed
            style = '--';
        else
            style = '-';
        end
        plot(t, stimulusFiltered(:,fi), 'Color', c, 'LineStyle',style)
    else
        plot(t, stimulusFiltered(:,fi))
    end
    hold on
end
grid on
ylabel('stimulus lowpass')
legend(locationNames)

axes(handles(2))
for si = 1:numSubunits
    plot(t, nim.subunits(si).weight * subunitOutputLN(:,si)/3)%, 'Color', colorsBySubunit(si,:))
    hold on
end
legend('sub 1','sub 2','sub 3','sub 4','sub 5','sub 6')
% legend('sub 1 out weighted (ON+)','sub 2 out weighted (ON-)','sub 3 out weighted (OFF)')
grid on
ylabel('subunit output')

% response
axes(handles(3));
plot(t, response, 'g')
hold on
% plot(t, generatingFunction, 'b:')
plot(t, responsePrediction, 'r')
ylim([0, max([max(response), max(responsePrediction)])])
grid on
legend('response','prediction')
ylabel('overall output')

linkaxes(handles, 'x')
xlim([1, 5])

pan xon


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% step response

if numSpatialDimensions == 4
    % color
    figure(206);clf;
    handles = tight_subplot(2,2, .1);
    stepStartTime = 0.5;
    stepEndTime = 1.0;
    offsetTime = 1.5;

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
        plot(t, artResponsePrediction_s, 'LineWidth',3)
    %     legend('stimulus','response')
        title(locationNames{ci})
    end
elseif numSpatialDimensions == 2


    figure(206);clf;
    stepStartTime = 0.5;
    stepEndTime = 1.0;
    offsetTime = 1.5;

    t = (0:1/updateRate:3)';
    artificialStim = zeros(size(t,1), 1);
    artificialStim(t >= stepStartTime & t <= stepEndTime) = 1;
    artificialStim(t - offsetTime >= stepStartTime & t - offsetTime <= stepEndTime) = -1;
    artXstim = NIM.create_time_embedding(artificialStim, params_stim);
    [~, artResponsePrediction_s] = nim.eval_model([], artXstim);

    plot(t, artificialStim);

    hold on
    plot(t, artResponsePrediction_s, 'LineWidth',3)
    title('Light step response prediction')
%     legend('stimulus','response')
    
end


%% spatial filters along a line
if numSpatialDimensions > 4
    figure(219);clf;
    % subunit filters
    dim1 = ceil(sqrt(numSpatialDimensions));
    dim2 = ceil(numSpatialDimensions / dim1);
    handles = tight_subplot(dim1, dim2, 0);
    
%     extractedParams = [];

    filterTime = (1:nLags)-1;
    filterTime = filterTime * stim_dt;
    h = [];
    for si = 1:numAdditiveSubunits
        
        h = [];
        filters = reshape(nim.subunits(si).filtK, [], numSpatialDimensions);
        for fi = 1:size(filters,2)
            axes(handles(fi));%handles(floor((fi-1) / 2) + 1));
%             c = colorsByColor(mod(fi-1, 2)+1,:);
            c = 'k';
            
            h(fi) = plot(filterTime, filters(:,fi), 'LineWidth',2, 'LineStyle',style, 'Color', c);
            
%             filt = filters(:,fi);
%             extractedParams(fi) = filt(2);

            hold on
%             line([0,max(filterTime)],[0,0],'Color','k', 'LineStyle',':');
            set(gca,'Xdir','reverse')
%             xlabel('time before output')
            if fi == 1
                title('filters for subunit 1 by position')
            end
        end

    end
    linkaxes(handles);
end

%% filters in space

for si = 1:2
    filters = reshape(nim.subunits(si).filtK, [], numSpatialDimensions);
    
    figure(230+si)
    imagesc(reshape(mean(filters(3:7,:)), 15, []))
    
end