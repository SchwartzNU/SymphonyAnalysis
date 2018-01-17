function MaxCorrs = noiseCorrelationAnalysis
startup


folder_name = uigetdir([ANALYSIS_FOLDER 'Projects/'],'Choose project folder');
obj.projFolder = [folder_name filesep];

fid = fopen([obj.projFolder 'cellNames.txt'], 'r');
if fid < 0
    errordlg(['Error: cellNames.txt not found in ' obj.projFolder]);
    close(obj.fig);
    return;
end

temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

for ii=1:length(cellNames)
    %% load data
    cellname = char(cellNames(ii));
    desiredVoltage = -60;
    sampleRate = 10000;
    AnalysisType = 'CenterSurroundNoise';
    
    load(['cellData/',cellname,'.mat'])
    SavedDataSets = cellData.savedDataSets.keys;
    MatchingDataSets = find(strncmp(SavedDataSets,AnalysisType,length(AnalysisType)));
    if ~any(MatchingDataSets)
        disp('A data set of this analysis type was not found for')
        disp(cellname)
        continue
    end
    
    MatchingEpochs = [];
    for iiii = 1:length(MatchingDataSets)
        S = SavedDataSets{MatchingDataSets(iiii)};
        MatchingEpochs = [MatchingEpochs,cellData.savedDataSets(S)];
    end
    
    MatchingEpochs = unique(MatchingEpochs);
    
    indices = [];
    speeds = [];
    voltages = [];
    responses = [];
    angles = [];
    oi = 0;
    
    for ei=1:length(MatchingEpochs)
        epoch = cellData.epochs(MatchingEpochs(ei));
        
        if epoch.get('ampHoldSignal') ~= desiredVoltage
            continue
        end
        oi = oi + 1;
        
        for channel = 1:2
            if channel == 1
                signalName = 'ampHoldSignal';
            else
                signalName = 'amp2HoldSignal';
            end
            
            indices(oi,1) = MatchingEpochs(ei);
            voltages(oi,channel) = epoch.get(signalName);
            if isnan(epoch.get(signalName))
                voltages(oi,1) = epoch.get('holdSignal');
            end
            
            
            if strcmp(epoch.get('ampMode'), 'Cell attached')
                response = zeros(size(epoch.getData(['Amplifier_Ch' num2str(channel)])));
                response(epoch.get(['spikes_ch' num2str(channel)])) = 1;
            else
                response = epoch.getData(['Amplifier_Ch' num2str(channel)]);
                
            end
            
            noiseTimeSec = [epoch.get('preTime')/1000, (epoch.get('preTime')+epoch.get('stimTime'))/1000];
            
            t = (0:length(response)-1)/10000;
            response = response(t > noiseTimeSec(1) & t <= noiseTimeSec(2));
            
            response = response - mean(response);
            
            [b,a] = butter(2,.1/5000,'high');
            response = filtfilt(b,a,response);
            
            responses(oi,:,channel) = response;
        end
    end
    
    
    for Chan = 1:2
        for TimPt = 1:length(responses(1,:,1))
            MeanResponses(1,TimPt,Chan) = mean(responses(:,TimPt,Chan));
        end
    end
    
    Ch1_PreSub = responses(6,:,1);
    Ch2_PreSub = responses(6,:,2);
    Ch1_Mean = MeanResponses(1,:,1);
    Ch2_Mean = MeanResponses(1,:,2);
    
    for Chan = 1:2
        for Trial = 1:length(responses(:,1,1))
            responses(Trial,:,Chan) = responses(Trial,:,Chan)-MeanResponses(1,:,Chan);      
        end
    end
    
    Ch1_PostSub = responses(6,:,1);
    Ch2_PostSub = responses(6,:,2);
    
    
    if isempty(responses)
        disp('no matching epochs')
        return
    end
    
    %%
    
    corrVals = [];
    for ei = 1:size(responses,1)
        [corrVals(ei, :), lags] = xcorr(responses(ei,:,1), responses(ei,:,2), 'coeff');
    end
    
    meanCorrelation = mean(corrVals, 1);
    SEMCorrelation = std(corrVals)/sqrt(length(corrVals(:,1)));
    [M,I] = max(abs(meanCorrelation));
    MaxCorr = mean(meanCorrelation(I-1:I+1));
    MaxCorrs(ii) = MaxCorr;
    
    
    numRandomCorrelations = 100;
    shuffledCorrelations = [];
    for si = 1:numRandomCorrelations
        shuffledOrder = randperm(size(responses,1));
        corrValsShuffledMean = [];
        for ei = 1:size(responses,1)
            corrValsShuffledMean(ei, :) = xcorr(responses(ei,:,1), responses(shuffledOrder(ei),:,2), 'coeff');
        end
        shuffledCorrelations(si,:) = mean(corrValsShuffledMean, 1);
    end
    corrValsShuffledMean = mean(shuffledCorrelations);
    corrValsShuffledSEM = std(shuffledCorrelations)/sqrt(numRandomCorrelations);
    
    %
            figure(99);
            clf
            shiftValues = lags / sampleRate;
            plot(shiftValues, meanCorrelation, 'b')
            hold on
            plot(shiftValues, meanCorrelation+SEMCorrelation,'-.b')
            plot(shiftValues, meanCorrelation-SEMCorrelation,'-.b')
    
    plot(shiftValues, corrValsShuffledMean, 'r')
    plot(shiftValues, corrValsShuffledMean+corrValsShuffledSEM, '-.r')
    plot(shiftValues, corrValsShuffledMean-corrValsShuffledSEM, '-.r')
    
            figure(111);
            clf
            h = tight_subplot(5,ceil(length(corrVals(:,1))/5));
            for ii = 1:length(corrVals(:,1))
                plot(h(ii), shiftValues(48500:51500), corrVals(ii,48500:51500))
            end
    
            set(h, 'YLim', [min(corrVals(:)), max(corrVals(:))]);
    
    
    s = struct();
    s.shiftValues = shiftValues;
    s.meanCorrelation = meanCorrelation;
    s.SEMCorrelation = SEMCorrelation;
    s.meanCorrelationShuffled = corrValsShuffledMean;
    s.SEMCorrelationShuffled = corrValsShuffledSEM;
    s.Ch1_PreSub = Ch1_PreSub;
    s.Ch2_PreSub = Ch2_PreSub;
    s.Ch1_Mean = Ch1_Mean;
    s.Ch2_Mean = Ch2_Mean
    s.Ch1_PostSub = Ch1_PostSub;
    s.Ch2_PostSub = Ch2_PostSub;
    
    exportStructToHDF5(s,[num2str(desiredVoltage), '_', cellname],'/')
end
