%% load data


load cellData/080817Ac3.mat
desiredBarSpeed = 1000;
desiredBarWidth = 75;
desiredIntensity = .595;
desiredVoltage = -60;

% load cellData/080817Ac5.mat
% sms
% desiredVoltage = -60;
% desiredPreTime = 500;

allEpochs = 1:length(cellData.epochs);

noiseTimeSec = [0.1, .3];
meanTimeSec = 0.1;

sampleRate = 10000;

indices = [];
speeds = [];
voltages = [];
responses = [];
angles = [];
oi = 0;

for ei=1:length(allEpochs)
    epoch = cellData.epochs(allEpochs(ei));
    
%     if ~strcmp(epoch.get('displayName'), 'Pulse')
%     if ~strcmp(epoch.get('displayName'), 'Spots Multi Size')
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
%     if epoch.get('preTime') ~= desiredPreTime
%         continue
%     end
%     
    if epoch.get('ampHoldSignal') ~= desiredVoltage
        continue
    end           
%     
%     if strcmp(epoch.get('ampMode'),'Cell attached')
%         continue
%     end    

    oi = oi + 1;
    
    for channel = 1:2
        
        if channel == 1
            signalName = 'ampHoldSignal';
        else
            signalName = 'amp2HoldSignal';
        end
        
        indices(oi,1) = allEpochs(ei);
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
        t = (0:length(response)-1)/10000;
        response = response(t > noiseTimeSec(1) & t <= noiseTimeSec(2));
        response = response - mean(response(1:(sampleRate*meanTimeSec)));
%         response = response(1:(sampleRate*noiseTimeSec));
    
        responses(oi,:,channel) = response;
    end
end
if isempty(responses)
    disp('no matching epochs')
    return
end

%%
% responsesExpanded = reshape(responses, size(responses,1)*size(responses,2),[]);
% 
% shuffledOrder = randperm(size(responses,1));
% responsesShuffled = responses(shuffledOrder, :,:);
% responsesExpandedShuffled = reshape(responsesShuffled, size(responses,1)*size(responses,2),[]);
% figure(101);clf;
% subplot(2,1,1)
% [correlation, lags] = xcorr(responsesExpanded(:,1), responsesExpanded(:,2), 'coeff');
% plot(lags / sampleRate, correlation)
% hold on
% [correlationShuffled, lags] = xcorr(responsesExpandedShuffled(:,1), responsesExpandedShuffled(:,2), 'coeff');
% plot(lags / sampleRate, correlationShuffled)
% % xlim([-.5, .5])
% legend('regular','shuffled')
% 
% subplot(2,1,2)
% plot(lags / sampleRate, smooth(smooth(correlation, 500) - smooth(correlationShuffled, 500), 100))





corrVals = [];
for ei = 1:size(responses,1)
    [corrVals(ei, :), lags] = xcorr(responses(ei,:,1), responses(ei,:,2), 'coeff');
end
meanCorrelation = mean(corrVals, 1);


numRandomCorrelations = 100;
shuffledCorrelations = [];
for si = 1:numRandomCorrelations
    si
    shuffledOrder = randperm(size(responses,1));
    corrValsShuffledMean = [];
    for ei = 1:size(responses,1)
        corrValsShuffledMean(ei, :) = xcorr(responses(ei,:,1), responses(shuffledOrder(ei),:,2), 'coeff');
    end
    shuffledCorrelations(si,:) = mean(corrValsShuffledMean, 1);
end
corrValsShuffledMean = mean(shuffledCorrelations);
corrValsShuffledStd = std(shuffledCorrelations);

%%
figure(99);
clf
shiftValues = lags / sampleRate;
plot(shiftValues, meanCorrelation)
hold on
plot(shiftValues, corrValsShuffledMean)
plot(shiftValues, corrValsShuffledMean-corrValsShuffledStd*2.576/sqrt(numRandomCorrelations))
plot(shiftValues, corrValsShuffledMean+corrValsShuffledStd*2.576/sqrt(numRandomCorrelations))


% plot(shiftValues, mean(corrValsShuffled, 1) - mean(corrVals, 1))
xlabel('channel 2 shift (sec)')
line([0,0],ylim(), 'LineStyle',':','Color','k')
% legend('regular','shuffled','diff')

s = struct();
s.shiftValues = shiftValues;
s.meanCorrelation = meanCorrelation;
s.meanCorrelationShuffled = corrValsShuffledMean;
s.meanCorrelationShuffledStd = corrValsShuffledStd;

exportStructToHDF5(s, 'correlation 080817Ac3.h5','/')


%% Plot responses collected at the same time

figure(144);clf;
h = tight_subplot(3,3);
for ei = 1:9
    plot(h(ei), squeeze(responses(ei,:,:)))
end
