%% load cellData responses for model comparison

load(sprintf('/Users/sam/analysis/cellData/%s.mat', cellName));


%%
% ex:

tEnd = 2.0;

barOrEdge = 1;
c_responses = {};

% ha = tight_subplot(12, 4);

% vi: 1 ex, 2 in, 3 spike rate over time, 4 flat line spike count
for vi = 1:3
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
        if barOrEdge == 1
            % width 200, speed 1000, length = 60
            if vi == 1 % ex
                startEpoch = 177;
                endEpoch = 196;
            elseif vi == 2 %in
                startEpoch = 251;
                endEpoch = 271;
            else % spikes
                startEpoch = 1; % missing data makes sam dissapointed in themself
                endEpoch = 1;
            end
        else % width = 1500
            if vi == 1 % ex
                startEpoch = 151;
                endEpoch = 176;
            elseif vi == 2 %in
                startEpoch = 272;
                endEpoch = 299;
            else % spikes
                startEpoch = 93;
                endEpoch = 121;
            end
        end
    elseif strcmp(cellName, '051216Ac9') % on alpha-like
        % width 200, speed 1000
        if vi == 1 % ex
            startEpoch = 115;
            endEpoch = 137;
        elseif vi == 2 %in
            startEpoch = 138;
            endEpoch = 161;
        else % spikes
            startEpoch = 11;
            endEpoch = 34;
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
            spikes = epoch.getSpikes() / 10000;
            spikes(spikes > tEnd) = [];
            if vi == 3
%                 spikeRate = zeros(size(response));
%                 spikeRate(spikes) = 1.0;
                tbins = 0:1/10000:tEnd;
                tbins = [tbins, inf];
                spikeRate = histcounts(spikes, tbins);
                response = spikeRate;
%                 response = filtfilt(hann(10000 / 10), 1, spikeRate); % 10 ms (100 samples) window filter
            elseif vi == 4
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
%         mn = smooth(mn, 30);
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