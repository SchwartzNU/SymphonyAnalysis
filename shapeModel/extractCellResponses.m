%% load cellData responses for model comparison

load('/Users/sam/analysis/cellData/060216Ac2.mat')

%%
% ex:

tEnd = 2.0;

for vi = 1:3;
    if vi == 1
        startEpoch = 343;
        endEpoch = 368;
    elseif vi == 2;
        startEpoch = 369;
        endEpoch = 390;
    else
        startEpoch = 103;
        endEpoch = 115;
    end
    
    epochIds = startEpoch:endEpoch;
    epochAngles = [];

    responses = [];
    c_angles = 0:30:330;

    for ei = 1:length(epochIds)
        epoch = cellData.epochs(epochIds(ei));
        epochAngles(ei) = epoch.get('barAngle'); %#ok<SAGROW>

        if vi < 3
            response = epoch.getData('Amplifier_Ch1');
        else
            spikes = epoch.getSpikes();
            spikeRate = zeros(size(response));
            spikeRate(spikes) = 1.0;
            response = filtfilt(hann(10000 / 10), 1, spikeRate); % 10 ms (100 samples) window filter
        end
        responses(ei,:) = response;
        

    %     ai = find(angles == angle);
    %     s = responses{ai};
    %     s(end+1,:) = response;
    end

    % angles = sort(unique(epochAngles));

%     figure(78)
%     plot(responses');

    %%
    means = [];


    % c_responses = {};

    for ai = 1:length(c_angles)
        epochIndices = find(epochAngles == c_angles(ai));
        mn = mean(responses(epochIndices,:), 1);
        mn = smooth(mn, 30);
        mn = mn(1:10000*tEnd+1);
        baseline = mean(mn(1:0.2*10000));
        mn = mn - baseline;
        
        st = std(responses(epochIndices,:), [], 1);
        st = smooth(st, 60);
        st = st(1:10000*tEnd+1);

        c_responses{vi,ai} = struct('mean',mn, 'std',st);
    end
end