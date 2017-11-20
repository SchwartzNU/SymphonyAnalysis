% IV analysis
% moving bar or SMS
% by angle or spot size

%% load data

%%% f mini off MB 500
% load cellData/070517Bc4.mat
% stimulus = 'mb';
% allEpochs = 1:465;
% channel = 1;
% binTime = 0.05;
% offsetByParameterTime = [0, -.12, -.28];
% parameter = 'barAngle';
% desiredBarSpeed = 500;
% desiredBarWidth = 200;
% desiredParameters = [90, 180, 270];
% desiredIntensity = 0.0;
% excludeEpochs = [];
% timesToMeasureIV = [3.2];
% timePlotLimits = [2.5, 3.8];
% measureTimeLineY = [-200, 300];
% singleTimePlotMode = true;
% parameterLabel = 'direction: %g deg';


% f mini On SMS
load cellData/080817Ac5.mat
cellName = '080817Ac5';
stimulus = 'sms';
channel = 1;
allEpochs = 1:length(cellData.epochs);
binTime = 0.05;
timesToMeasureIV = [.8];
offsetByParameterTime = [0, 0, 0, 0];
desiredParameters = [82, 160, 858];
desiredIntensity = 0.7;
parameter = 'curSpotSize';
excludeEpochs = [];
timePlotLimits = [.45 1.5];
measureTimeLineY = [-400, 450];
singleTimePlotMode = true;
parameterLabel = 'diameter: %g µm';

%%% F mini Off SMS with nice current plots
% load cellData/081517Bc3.mat
% cellName = '081517Bc3';
% stimulus = 'sms';
% channel = 1;
% allEpochs = 1:length(cellData.epochs);
% binTime = 0.02;
% timesToMeasureIV = [.66, 1.3, 1.8];
% offsetByParameterTime = [0, 0, 0, 0];
% desiredParameters = [160, 858];
% desiredIntensity = 0;
% parameter = 'curSpotSize';
% parameterLabel = 'diameter: %g µm';
% excludeEpochs = [202, 491];
% timePlotLimits = [0.4, 2.5];
% measureTimeLineY = [-250, 120];
% singleTimePlotMode = true;

% F mini Off SMS
% load cellData/080817Bc1.mat
% cellName = '080817Bc1';
% stimulus = 'sms';
% channel = 1;
% allEpochs = 1:length(cellData.epochs);
% binTime = 0.01;
% timesToMeasureIV = [.8, 1.0, 1.2];
% offsetByParameterTime = [0, 0, 0];
% desiredParameters = [160, 1200];
% desiredIntensity = 0.3;
% parameter = 'curSpotSize';
% excludeEpochs = [];
% timePlotLimits = [0, 2];
% measureTimeLineY = [-200, 300];
% singleTimePlotMode = true;

% load cellData/040716Ac8.mat
% allEpochs = 125:204;
% allEpochs = 166:203;
% offsetByParameter = [-4,0]; % for 040716Ac8
% channel = 2;


% load cellData/041416Bc13.mat
% allEpochs = 371:408;

% paired cells, On 1, F mini Off 2
% load cellData/071917Ac3.mat
% allEpochs = 233:512;
% channel = 1;
% timeBinIndicesToPlot = [25, 45, 51, 64, 100];
% offsetByParameter = [2,0]; 
% desiredBarSpeed = 500;
% desiredBarWidth = 1000;
% desiredParameters = [0];
% desiredIntensity = 1.0;


figOffset = 100 * (channel - 1);
meanTimeSec = 0.5;

sampleRate = 10000;

% offsetByParameter = [-8,-14]; 
% offsetByParameter = [-7,-14]; 

indices = [];
voltages = [];
responses = [];
parameterValues = [];
offsetByParameterBins = round(offsetByParameterTime ./ binTime); 
oi = 0;



for ei=1:length(allEpochs)
    epoch = cellData.epochs(allEpochs(ei));
    

    
%     if epoch.get('spotSize') ~= 1000
%         continue
%     end
    
%     if epoch.get('ampHoldSignal') == -40
%         continue
%     end
    if any(allEpochs(ei) == excludeEpochs)
        continue
    end
    

    if strcmp(stimulus, 'mb')
        if ~strcmp(epoch.get('displayName'), 'Moving Bar')
    %     if ~strcmp(epoch.get('displayName'), 'IV Curve')
            continue
        end
    
        if epoch.get('barSpeed') ~= desiredBarSpeed
            continue
        end

        if epoch.get('barWidth') ~= desiredBarWidth
            continue
        end    

        if epoch.get('intensity') ~= desiredIntensity
            continue
        end    

        if ~any(epoch.get('barAngle') == desiredParameters)
            continue
        end    
        
    elseif strcmp(stimulus, 'sms')
        if ~strcmp(epoch.get('displayName'), 'Spots Multi Size')
            continue
        end
        
        
        round(epoch.get(parameter))
        if ~any(round(epoch.get(parameter)) == desiredParameters)
            continue
        end    
        
        if epoch.get('intensity') ~= desiredIntensity
            continue
        end            
        
        if strcmp(cellName, '081517Bc3') && epoch.get('ampHoldSignal') == -60 && epoch.get('epochNum') < 260
            continue
        end
    end
    
    if strcmp(epoch.get('ampMode'),'Cell attached')
        continue
    end

    oi = oi + 1;
    indices(oi,1) = allEpochs(ei);
    if channel == 1
        signalName = 'ampHoldSignal';
    else
        signalName = 'amp2HoldSignal';
    end
    voltages(oi,1) = epoch.get(signalName);
    if isnan(epoch.get(signalName))
        voltages(oi,1) = epoch.get('holdSignal');
    end
    parameterValues(oi,1) = round(epoch.get(parameter));

    if strcmp(epoch.get('ampMode'), 'Cell attached')
        response = zeros(size(epoch.getData(['Amplifier_Ch' num2str(channel)])));
        response(epoch.get(['spikes_ch' num2str(channel)])) = 1;
    else       
        response = epoch.getData(['Amplifier_Ch' num2str(channel)]);
        
    end
    
    response = response - mean(response(1:(sampleRate*meanTimeSec)));
    
    responses(oi,:) = response;
end
if isempty(responses)
    disp('No epochs found')
    return
end

figure(101)
plot(responses')
title('all responses')


%% bin data by voltage and time
figure(111+figOffset);clf;
set(gcf,'color','w');

timeBinIndicesToPlot = floor(timesToMeasureIV / binTime);

uvoltages = flipud(unique(voltages));
responsesByVoltage = [];
responseByVoltageAngleBin = [];


colorByMeasuretime = copper(length(timesToMeasureIV));
colorByVoltage = flipud(jet(length(uvoltages)));
styles = {'-','--',':','-.','-'};
plotBackgroundColor = .8 * [1 1 1];
legendTextColor = 'k';

binLength = binTime * sampleRate;
bin = ones(1,binLength);
timeBinIndices = [];
legendHandles = [];

for n = 1:ceil(length(responses)/binLength)
    timeBinIndices = horzcat(timeBinIndices, bin * n);
end

if singleTimePlotMode
    h = tight_subplot(1,length(desiredParameters), .07, .2, .2);
else
    h = tight_subplot(length(uvoltages),length(desiredParameters), .04, .1);
end

exportStruct = struct();

for ai = 1:length(desiredParameters)
        
    for vi = 1:length(uvoltages)

        responseMean = mean(responses(voltages == uvoltages(vi) & parameterValues == desiredParameters(ai), :), 1);
        responsesByVoltage(vi,:) = responseMean;
        responseByVoltageAngleBin(vi,ai,:) = accumarray(timeBinIndices', responseMean', [], @mean)';

        
        if singleTimePlotMode
            axes(h(ai))
        else
            axes(h((vi-1)*length(desiredParameters) + ai))
        end
        plotLine = squeeze(responseByVoltageAngleBin(vi,ai,:));
        
        t = ((0:length(plotLine)-1) * binTime)' - offsetByParameterTime(ai);
        legendHandles(vi) = plot(t, plotLine, 'Color', colorByVoltage(vi,:), 'LineWidth',2);
        hold on
        plot(t(timeBinIndicesToPlot) + offsetByParameterTime(ai), plotLine(timeBinIndicesToPlot + offsetByParameterBins(ai)), '.', 'MarkerSize', 20, 'Color', colorByVoltage(vi,:))
        
        if ~singleTimePlotMode
            for bi = 1:length(timeBinIndicesToPlot)
                l = line([t(timeBinIndicesToPlot(bi)), t(timeBinIndicesToPlot(bi))] + offsetByParameterTime(ai), measureTimeLineY, 'Color', colorByMeasuretime(bi,:), 'LineStyle', styles{ai}, 'LineWidth',2.5);
%                 uistack(l, 'top')
            end
        end
        
        ax = gca();
        ax.FontName = 'Roboto';
        ax.FontSize = 14;
        ax.Box = 'off';
        ax.Color = plotBackgroundColor;
        if singleTimePlotMode
            title(sprintf(parameterLabel, desiredParameters(ai)))
        else
            title(sprintf('Voltage: %g mV, %s: %g', uvoltages(vi),parameter, desiredParameters(ai)))
        end
        
        xlim(timePlotLimits)
        ylim(measureTimeLineY)
        ylabel('current (pA)');
        xlabel('time (sec)');
%         set(gca, 'XTick', [])
%         ylim([min(plotLine)*1.1-.1, max(plotLine) * 1.1])
        exportStruct.t = t;
        if uvoltages(vi) > 0
            exportStruct.(sprintf('current_v%g',uvoltages(vi))) = plotLine;
        else
            exportStruct.(sprintf('current_vneg%g',abs(uvoltages(vi)))) = plotLine;
        end
        if ai == length(desiredParameters)
            leg = legend(legendHandles, compose('%g mV', uvoltages), 'Location','east','AutoUpdate','off');
            leg.TextColor = legendTextColor;
%             leg.Box = 'off';
        end
        
    end
   
end
if ~singleTimePlotMode
    for vi = 1:length(uvoltages)
        row = (1:length(desiredParameters)) + (vi-1)*length(desiredParameters);
        linkaxes(h(row))
    end
else
    % add vertical lines
    for ai = 1:length(desiredParameters)
        axes(h(ai));
        for bi = 1:length(timeBinIndicesToPlot)
            l = line([timesToMeasureIV(bi)-binTime, timesToMeasureIV(bi)-binTime], measureTimeLineY, 'Color', colorByMeasuretime(bi,:), 'LineStyle', styles{ai}, 'LineWidth',3);
            uistack(l, 'bottom')
        end
    end
end



%% Plot a few times over voltage


% responseByVoltageAtTime = responseByVoltageBin(:, timeBinIndex);

figure(121+figOffset);clf;
set(gcf,'color','w');

responseByVoltageAngleBinSelected = [];
for ai = 1:length(desiredParameters)
    timeBinIndicesToPlotWithOffset = timeBinIndicesToPlot + offsetByParameterBins(ai);
    for bi = 1:length(timeBinIndicesToPlotWithOffset)
        plot(uvoltages, responseByVoltageAngleBin(:,ai,timeBinIndicesToPlotWithOffset(bi))', styles{ai}, 'Color', colorByMeasuretime(bi,:), 'LineWidth',2.5)
        grid on
        hold on
        responseByVoltageAngleBinSelected(:,ai,bi) = responseByVoltageAngleBin(:,ai,timeBinIndicesToPlotWithOffset(bi));
        
        exportStruct.v = uvoltages;
        exportStruct.(sprintf('current_t%g',timesToMeasureIV(bi)*100)) = responseByVoltageAngleBin(:,ai,timeBinIndicesToPlotWithOffset(bi));
    end
    

end
xlim([min(voltages), max(voltages)])
ax = gca();
ax.FontName = 'Roboto';
ax.FontSize = 14;
ax.Box = 'off';
ax.Color = plotBackgroundColor;
% title('Current vs Voltage at several bar angles')
% legend(cellstr(num2str(timeBinIndicesToPlot' * binTime, '%g sec')), 'Location','Best')
xlabel('holding voltage (mV)')
ylabel('current (pA)')

% % Difference between angles
% if length(desiredParameters) > 1
%     figure(122+figOffset);clf;
%     differenceByVoltageBin = squeeze(diff(responseByVoltageAngleBinSelected, [], 2));
%     for bi = 1:length(timeBinIndicesToPlot)
% 
%         plot(uvoltages, differenceByVoltageBin(:,bi), styles{ai}, 'Color', colors(bi,:))
%         grid on
%         hold on
%     end
%     title('diff preferred to null')
%     % legend(cellstr(num2str(timeBinIndicesToPlot', 'N=%-d')), 'Location','Best')
% end
% 
