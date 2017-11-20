
% load cellData/071917Ac3.mat
allEpochs = 8:104;

noiseTimeSec = 0.5;
meanTimeSec = 0.1;

sampleRate = 10000;

indices = [];
speeds = [];
voltages = [];
responses = [];
outputAmps = [];
oi = 0;

for ei=1:length(allEpochs)
    epoch = cellData.epochs(allEpochs(ei));
    
    if ~strcmp(epoch.get('displayName'), 'Pulse')
%     if ~strcmp(epoch.get('displayName'), 'IV Curve')
        continue
    end

    if strcmp(epoch.get('ampMode'),'Cell attached')
        continue
    end    
    
    if epoch.get('

    oi = oi + 1;
    
    outputAmps(oi,1) = epoch.get('outputAmpSelection');

    
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
    
        response = response - mean(response(1:(sampleRate*meanTimeSec)));
    
        responses(oi,:,channel) = response;
    end
end

%%
figure(140)
clf;

selects = outputAmps == 1;
displayChannel = 2;

t = (0:1/sampleRate:1.4999) - .5;
signal = mean(responses(selects, :, displayChannel));
plot(t, signal)
grid on
line(xlim(), [0,0], 'LineWidth', 3, 'Color','k')
line([0,0],ylim(), 'LineWidth', 3, 'Color','k')
