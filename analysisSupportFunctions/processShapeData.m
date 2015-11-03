function outputData = processShapeData(epochData)
% runmode: 'online' or 'offline'
% responsemode: 'wc' or 'ca'
% epochData: cell array of epochs (format varies by runmode)
% signalData: include signals from cell


outputData = struct();

num_epochs = size(epochData, 1);

defaultOffset = 0.1; % feedforward network has a delay

%% create full positions list
col_x = epochData{1}.shapeDataColumns('X');
col_y = epochData{1}.shapeDataColumns('Y');
col_intensity = epochData{1}.shapeDataColumns('intensity');

all_positions = [];
for p = 1:num_epochs
    all_positions = vertcat(all_positions, epochData{p}.shapeData(:,[col_x col_y]));
end

all_positions = unique(all_positions, 'rows');
responseData = cell(length(all_positions),1);

for p = 1:num_epochs
    e = epochData{p};
    outputData.spotTotalTime = e.spotTotalTime;
    outputData.spotOnTime = e.spotOnTime;
    outputData.numSpots = e.numSpots;

    epoch_positions = e.shapeData(:,[col_x col_y]);
    epoch_intensities = e.shapeData(:,col_intensity);
    

    %% find the time offset from light to spikes, assuming On semi-transient cell
    lightValue = 1.0 * (mod(e.t, e.spotTotalTime) < e.spotOnTime);
    [c,lags] = xcorr(e.spikeRate, lightValue);
    lags = lags ./ e.sampleRate;
    c = c .* (1 - abs(lags' / e.spotTotalTime) * .1); % bias toward low values
    [~,I] = max(c);
    t_offset = lags(I) - defaultOffset + e.spotTotalTime;
    t_basis = e.t - t_offset;

    sampleCount = round(e.spotTotalTime * e.sampleRate);
    displayTime = t_basis(1:sampleCount) + e.spotTotalTime;
    spikeRate_by_spot = zeros(e.numSpots, sampleCount);
    for si = 1:e.numSpots
        spot_position = epoch_positions(si,:);
        spot_intensity = epoch_intensities(si);
        
        segmentStartIndex = find(t_basis > e.spotTotalTime * (si - 1), 1);
%         t_range = (t - t_offset) > spotTotalTime * (si - 1) & (t - t_offset) < spotTotalTime * si;
        segmentIndices = segmentStartIndex + (0:(sampleCount-1))';
        spikeRate_by_spot(si,:) = e.spikeRate(segmentIndices);
        
        all_position_index = all_positions(:,1) == spot_position(1) & all_positions(:,2) == spot_position(2);
        response = mean(e.spikeRate(segmentIndices));
        responseData{all_position_index} = vertcat(responseData{all_position_index}, [spot_intensity, response]);
        
%         title(si)
%         plot(t_basis(segmentIndices), spikeRate_by_spot(si,:), t_basis(segmentIndices), lightValue(segmentIndices))
%         drawnow
%         pause
%         spikes = spikeTimes > t_range(1) & spikeTimes < t_range(2);
%         spikeRate_by_spot(end+1,:) = spikeRateSegment;
%         responseValues(end+1,1) = sum(spikes);
    end

    
end

%% overall analysis
simpleResponses = zeros(length(responseData), 1);

for p = 1:length(responseData)
    r = responseData{p,1};
    spikes = mean(r(r(:,1) == 1.0, 2)); % just get the intensity 1.0 ones
    simpleResponses(p,1) = spikes;
end

zlist = simpleResponses;

centerOfMassXY = [sum(all_positions(:,1) .* zlist)/sum(zlist), sum(all_positions(:,2) .* zlist)/sum(zlist)];

% find the farthest point above a threshold level for autocenter refinement
positions_rel = [all_positions(:,1) - centerOfMassXY(1), all_positions(:,2) - centerOfMassXY(2)];
distances = sqrt(sum(positions_rel .^ 2, 2));
prz = [positions_rel, distances, simpleResponses];
prz = sortrows(prz, 3); % sort on distances
% max_response = max(simpleResponses);
% prz
farthestResponseDistance = prz(find(prz(:,4) > 0, 1, 'last'), 3);
% figure(12)
% plot(prz(:,3), prz(:,4))


%% store data for the next stages of processing/output
outputData.positions = all_positions;
outputData.responseData = responseData;
outputData.spikeRate_by_spot = spikeRate_by_spot;
outputData.displayTime = displayTime; 
outputData.timeOffset = t_offset;
outputData.centerOfMassXY = centerOfMassXY;
outputData.farthestResponseDistance = farthestResponseDistance;


end