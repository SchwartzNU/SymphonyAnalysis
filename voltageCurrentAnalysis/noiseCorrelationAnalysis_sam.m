

% inputs
%%% CHANGE STUFF HERE
desiredVoltage = 0;
AnalysisType = 'Pulse';
%%%

%export:

dataLabel = 'MFA';

% folder_name = uigetdir([ANALYSIS_FOLDER 'Projects/'],'Choose project folder');
% obj.projFolder = [folder_name filesep];
% 
% fid = fopen([obj.projFolder 'cellNames.txt'], 'r');
% if fid < 0
%     errordlg(['Error: cellNames.txt not found in ' obj.projFolder]);
%     close(obj.fig);
%     return;
% end
% 
% temp = textscan(fid, '%s', 'delimiter', '\n');diar
% cellNames = temp{1};
% fclose(fid);

cellNames = {'080318Ac2'};
AnalysisType = 'Pulse MFA all';
% AnalysisType = 'Pulse control all';
% AnalysisType = 'RandomMotionObject MFA late seedvarying';
% AnalysisType = 'RandomMotionObject MFA late seed20';
% AnalysisType = 'RandomMotionObject spiking pair set1 seed10';
% AnalysisType = 'RandomMotionObject spiking pair set1 seedvarying';

% cellNames = {'100318Ac6'}; % no flip with MFA, obviously still strongly connected
% AnalysisType = 'Pulse output1 control';
% AnalysisType = 'Pulse output1 MFA';

% cellNames = {'031518Ac1'};
% AnalysisType = 'Pulse output fmon';

% cellNames = {'040819Ac4'};
% AnalysisType = 'RandomMotionObject control';
% AnalysisType = 'RandomMotionObject MFA';
% AnalysisType = 'RandomMotionObject varyingSeed control';
% AnalysisType = 'RandomMotionObject varyingSeed MFA';
% AnalysisType = 'RandomMotionObject sameSeed control';
% AnalysisType = 'RandomMotionObject sameSeed MFA';


% cellNames = {'040819Ac4'};
% cellNames = {'031419Ac2'};


% cellNames = {'060118Ac2'};
% cellNames = {'050918Ac4'};
% cellNames = {'040618Ac2'};
% cellNames = {'042618Ac9'};
cellNames = {'080818Ac3'};
AnalysisType = 'Pulse MFA late';

enableMeanSubtraction = 0;

drawPlotsByEpoch = 0;

exportToHDF5 = 0;

sampleRate = 10000;
f = 1; % Hz
% d = designfilt('highpassiir', 'SampleRate', sampleRate,...
% 	'StopbandFrequency', f*0.8,...
% 	'PassbandFrequency', f*1.3,...
% 	'StopbandAttenuation', 40, ...
%  	'PassbandRipple', 5);

% d = designfilt('bandpassiir', 'SampleRate', sampleRate,...
% 	'HalfPowerFrequency1', .5,...
% 	'HalfPowerFrequency2', 500,...
% 	'FilterOrder', 50);

cellIndex=1;

%% load data

figure(29);clf;

cellName = cellNames{cellIndex};

load(['cellData/',cellName,'.mat'])
SavedDataSets = cellData.savedDataSets.keys;
MatchingDataSets = find(strncmp(SavedDataSets,AnalysisType,length(AnalysisType)));
if ~any(MatchingDataSets)
    disp('A data set of this analysis type was not found for')
    disp(cellName)
    return
end

MatchingEpochs = [];
for cici = 1:length(MatchingDataSets)
    S = SavedDataSets{MatchingDataSets(cici)};
    MatchingEpochs = [MatchingEpochs,cellData.savedDataSets(S)];
end

MatchingEpochs = unique(MatchingEpochs)


%     MatchingEpochs = [521, 522, 523, 524]; % MFA
%     MatchingEpochs = [253,254]; % control
%     MatchingEpochs = [248:254];

indices = [];
speeds = [];
voltages = [];
responses = [];
responseMeanOverTrials = [];
angles = [];
oi = 0;

maxPlotsToDraw = 10;
numPlotsToDraw = min([maxPlotsToDraw, length(MatchingEpochs)]);

if drawPlotsByEpoch
    [~,hgrid] = tight_subplot(length(MatchingEpochs)+1, 2);
end


for ei=1:length(MatchingEpochs)
    epoch = cellData.epochs(MatchingEpochs(ei));

%         if epoch.get('ampHoldSignal') ~= desiredVoltage
%             continue
%         end
    oi = oi + 1

    for channel = 1:2
        if channel == 1
            signalName = 'ampHoldSignal';
        else
            signalName = 'amp2HoldSignal';
        end

        indices(oi,1) = MatchingEpochs(ei);
        voltages(oi,channel) = epoch.get(signalName);
        motionSeed = epoch.get('motionSeed');
        if isnan(epoch.get(signalName))
            voltages(oi,1) = epoch.get('holdSignal');
        end

        if strcmp(epoch.get('ampMode'), 'Cell attached')
            response = zeros(size(epoch.getData(['Amplifier_Ch' num2str(channel)])));
            response(epoch.get(['spikes_ch' num2str(channel)])) = 1;
        else
            response = epoch.getData(['Amplifier_Ch' num2str(channel)]);

        end

        % subset of epoch time for analysis
        t = (0:length(response)-1)/10000;

         % pretime
            noiseTimeSec = [0, epoch.get('preTime')/1000];
            tSelect = t > noiseTimeSec(1) & t <= noiseTimeSec(2);

        % stim start to epoch end
%             noiseTimeSec = [(epoch.get('preTime')+epoch.get('stimTime'))+500, inf]/1000;
%             tSelect = t > noiseTimeSec(1) & t <= noiseTimeSec(2);

        % during stim
%         noiseTimeSec = [epoch.get('preTime')/1000, (epoch.get('preTime')+epoch.get('stimTime'))/1000];
%         tSelect = t > noiseTimeSec(1) & t <= noiseTimeSec(2);

        % last 300ms of each epoch
%             noiseTimeSec = [(epoch.get('preTime')+epoch.get('stimTime'))/1000, (epoch.get('preTime')+epoch.get('stimTime'))/1000] - [.3, 0];
%             tSelect = t > noiseTimeSec(1) & t <= noiseTimeSec(2);

%             post stim
%         noiseTimeSec = [(epoch.get('preTime')+epoch.get('stimTime'))/1000 + .3, inf];
%         tSelect = t > noiseTimeSec(1) & t <= noiseTimeSec(2);

        % pre and post stim
%             noiseTimeSec = [0, epoch.get('preTime')/1000, (epoch.get('preTime')+epoch.get('stimTime'))/1000 + .3, inf];
%             tSelect = (t > noiseTimeSec(1) & t <= noiseTimeSec(2)) | (t > noiseTimeSec(3) & t <= noiseTimeSec(4));

        % entire epoch
%             noiseTimeSec = [0, epoch.get('stimTime')/1000];



        response = response(tSelect);
        response = response - mean(response);
        %[b,a] = butter(8,0.5/(sampleRate/2),'high');
        response_filt = response;
        
%         response_filt = filtfilt(d,[zeros(10000,1);response;zeros(10000,1)]);
%         response_filt = response_filt([10001:end-10000]);
% 
% 

%         if channel == 2
%           warning('experiment shift enabled')
%             response_filt = circshift(response_filt, 0.1 * 10000);
%         end
        responses(oi,channel,:) = response_filt;



%             figure(29)
%             subplot(length(MatchingEpochs), 1, oi);
        if drawPlotsByEpoch
            axes(hgrid(ei, channel));
            plot(t(tSelect), response)
    %         hold on
    %         plot(response_filt)
            title(sprintf('epoch responses seed %g', motionSeed))
        end

    end
    hold off
    drawnow
end

if oi == 0
    warning('No matching epochs')
    return
end

numEpochs = size(responses,1);

if enableMeanSubtraction
    % mean over each trial
    for channel = 1:2
        responseMeanOverTrials(channel,:) = squeeze(mean(responses(:, channel, :), 1));
        
        axes(hgrid(end,channel))
        plot(t(tSelect), responseMeanOverTrials(channel,:));
        title('mean');
    end

    Ch1_PreSub = squeeze(responses(:,:,1));
    Ch2_PreSub = squeeze(responses(:,:,2));
    Ch1_Mean = responseMeanOverTrials(1,:);
    Ch2_Mean = responseMeanOverTrials(2,:);

    for channel = 1:2
        for ei = 1:numEpochs
            responses(ei,channel,:) = squeeze(responses(ei,channel,:))-responseMeanOverTrials(channel,:)';
            
            axes(hgrid(ei, channel));
            hold on
            plot(t(tSelect), squeeze(responses(ei,channel,:)))
        end
    end
end

drawnow


Ch1_PostSub = responses(:,1,:);
Ch2_PostSub = responses(:,2,:);


if isempty(responses)
    disp('no matching epochs')
    return
end

%%

corrVals = [];
for ei = 1:numEpochs
    [corrVals(ei, :), lags] = xcorr(squeeze(responses(ei,1,:)), squeeze(responses(ei,2,:)), 20000, 'coeff');
end

meanCorrelation = mean(corrVals, 1);
SEMCorrelation = std(corrVals)/sqrt(length(corrVals(:,1)));
[M,I] = max(abs(meanCorrelation));
MaxCorr = mean(meanCorrelation(I-1:I+1));
MaxCorrs(cellIndex) = MaxCorr;


numRandomCorrelations = 30;
shuffledCorrelations = [];
for si = 1:numRandomCorrelations
    si
    shuffledOrder = randperm(numEpochs);
    corrValsShuffledMean = [];
    for ei = 1:numEpochs
        corrValsShuffledMean(ei, :) = xcorr(squeeze(responses(ei,1,:)), squeeze(responses(shuffledOrder(ei),2,:)), 20000, 'coeff');
    end
    shuffledCorrelations(si,:) = mean(corrValsShuffledMean, 1);
end
corrValsShuffledMean = mean(shuffledCorrelations);
corrValsShuffledSEM = std(shuffledCorrelations)/sqrt(numRandomCorrelations);

%
figure(102 + abs(desiredVoltage));
clf;
subplot(length(cellNames), 1, cellIndex)
shiftValues = lags / sampleRate;
plot(shiftValues, meanCorrelation, 'b')
hold on
plot(shiftValues, meanCorrelation+SEMCorrelation,'-.b')
plot(shiftValues, meanCorrelation-SEMCorrelation,'-.b')

plot(shiftValues, corrValsShuffledMean, 'r')
plot(shiftValues, corrValsShuffledMean+corrValsShuffledSEM, '-.r')
plot(shiftValues, corrValsShuffledMean-corrValsShuffledSEM, '-.r')
xlabel('shift time (s)')
title('cross correlation (blue)')
[ma, mi] = max(abs(meanCorrelation));
fprintf('Corr peak: %g at %g sec\n', ma, shiftValues(mi));

xlim([-1,1])
fprintf('FWHM (sec): %g\n', fwhm(shiftValues, meanCorrelation));

if drawPlotsByEpoch
    figure(111+cellIndex);
    clf
    % h = tight_subplot(5,ceil(length(corrVals(:,1))/5));
    h = tight_subplot(length(MatchingEpochs),1);
    for cc = 1:length(corrVals(:,1))
     %plot(h(ci), shiftValues(48500:51500), corrVals(ci,48500:51500))
        plot(h(cc), shiftValues, corrVals(cc,:))
        title(h(cc), sprintf('%g:%g', cc, MatchingEpochs(cc)))
    end

    set(h, 'YLim', [min(corrVals(:)), max(corrVals(:))]);
end

s = struct();
s.shiftValues = shiftValues;
s.meanCorrelation = meanCorrelation;
s.meanCorrelation_plusSEM = meanCorrelation + SEMCorrelation;
s.meanCorrelation_minusSEM = meanCorrelation - SEMCorrelation;
s.SEMCorrelation = SEMCorrelation;

s.meanCorrelationShuffled = corrValsShuffledMean;
s.meanCorrelationShuffled_plusSEM = corrValsShuffledMean + corrValsShuffledSEM;
s.meanCorrelationShuffled_minusSEM = corrValsShuffledMean - corrValsShuffledSEM;
s.SEMCorrelationShuffled = corrValsShuffledSEM;

% s.Ch1_PreSub = Ch1_PreSub;
% s.Ch2_PreSub = Ch2_PreSub;
% s.Ch1_Mean = Ch1_Mean;
% s.Ch2_Mean = Ch2_Mean;
% s.Ch1_PostSub = Ch1_PostSub;
% s.Ch2_PostSub = Ch2_PostSub;

fname = sprintf('igorExport/xcorr %s.h5', cellName);
% delete(fname)
if exportToHDF5
    exportStructToHDF5(s, fname, dataLabel)
end

disp('Done')
