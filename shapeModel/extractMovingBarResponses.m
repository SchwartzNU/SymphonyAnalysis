%% load cellData responses for model comparison

load(sprintf('/Users/sam/analysis/cellData/%s.mat', cellName));


%%
% ex:

tEnd = 2.0;

for vi = 1:2;
    if strcmp(cellName, '060216Ac2')
        if vi == 1 % ex
            startEpoch = 343;
            endEpoch = 368;
        elseif vi == 2 %in
            startEpoch = 369;
            endEpoch = 390;
        else % spikes
            startEpoch = 103;
            endEpoch = 115;
        end
    elseif strcmp(cellName, '060716Ac2')
        % width 200, speed 1000
        if vi == 1 % ex
            startEpoch = 470;
            endEpoch = 494;
        elseif vi == 2 %in
            startEpoch = 495;
            endEpoch = 518;
        else % spikes
            startEpoch = 69;
            endEpoch = 81;
        end        
    elseif strcmp(cellName, '033116Ac2')
        % width 200, speed 1000
        if vi == 1 % ex
            startEpoch = 177;
            endEpoch = 196;
        elseif vi == 2 %in
            startEpoch = 251;
            endEpoch = 271;
        else % spikes
            startEpoch = 69;
            endEpoch = 81;
        end        
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
            if vi < 4
                spikeRate = zeros(size(response));
                spikeRate(spikes) = 1.0;
                response = filtfilt(hann(10000 / 10), 1, spikeRate); % 10 ms (100 samples) window filter
            else
                response = ones(length(response),1) * length(spikes);
            end
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
        st = smooth(st, 200);
        st = st(1:10000*tEnd+1);

        c_responses{vi,ai} = struct('mean',mn, 'std',st);
    end
end

disp('done')