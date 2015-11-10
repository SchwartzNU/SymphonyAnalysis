function od = processShapeData(epochData)
% epochData: cell array of ShapeData

od = struct();

num_epochs = size(epochData, 1);

defaultOffset = 0.1; % feedforward network has a delay

%% create full positions list
col_x = epochData{1}.shapeDataColumns('X');
col_y = epochData{1}.shapeDataColumns('Y');
col_intensity = epochData{1}.shapeDataColumns('intensity');

all_positions = [];
for p = 1:num_epochs
    all_positions = vertcat(all_positions, epochData{p}.shapeDataMatrix(:,[col_x col_y]));
end
all_positions = unique(all_positions, 'rows');
responseData = cell(length(all_positions), 1);

for p = 1:num_epochs
    e = epochData{p};
    od.spotTotalTime = e.spotTotalTime;
    od.spotOnTime = e.spotOnTime;
    od.numSpots = e.numSpots;

    epoch_positions = e.shapeDataMatrix(:,[col_x col_y]);
    epoch_intensities = e.shapeDataMatrix(:,col_intensity);
    

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
    for si = 1:e.totalNumSpots
        spot_position = epoch_positions(si,:);
        spot_intensity = epoch_intensities(si);
        
        segmentStartIndex = find(t_basis > e.spotTotalTime * (si - 1), 1);
        if isempty(segmentStartIndex)
            continue
        end
%         t_range = (t - t_offset) > spotTotalTime * (si - 1) & (t - t_offset) < spotTotalTime * si;
        segmentIndices = segmentStartIndex + (0:(sampleCount-1))';
        if size(e.spikeRate, 1) < max(segmentIndices)
            continue
        end
        spikeRate_by_spot(si,:) = e.spikeRate(segmentIndices);
        
        all_position_index = all_positions(:,1) == spot_position(1) & all_positions(:,2) == spot_position(2);
%         all_pos_in = find(all_position_index)
        response = mean(e.spikeRate(segmentIndices)); % average of spike rate over time chunk
%         current_data = responseData{all_position_index, 1}
        responseData{all_position_index,1} = vertcat(responseData{all_position_index,1}, [spot_intensity, response]);
        
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
maxIntensityResponses = zeros(length(responseData), 1);

highestIntensity = -Inf;
% find highest intensity
for p = 1:length(responseData)
    r = responseData{p,1};
    highestIntensity = max(max(r(:,1)), highestIntensity);
end

% get the responses at that intensity for simple mapping
for p = 1:length(responseData)
    r = responseData{p,1};
    spikes = mean(r(r(:,1) == highestIntensity, 2)); % just get the intensity 1.0 ones
    maxIntensityResponses(p,1) = spikes;
end

centerOfMassXY = [sum(all_positions(:,1) .* maxIntensityResponses)/sum(maxIntensityResponses), ...
                    sum(all_positions(:,2) .* maxIntensityResponses)/sum(maxIntensityResponses)];

% find the farthest point above a threshold level for autocenter refinement
positions_rel = bsxfun(@plus, all_positions, -1*centerOfMassXY);
distances = sqrt(sum(positions_rel .^ 2, 2));
pos_dist_intensity = [positions_rel, distances, maxIntensityResponses];
pos_dist_intensity = sortrows(pos_dist_intensity, 3); % sort on distances

%TODO: figure out the right threshold for the distance refinement
% max_response = max(simpleResponses);
farthestResponseDistance = pos_dist_intensity(find(pos_dist_intensity(:,4) > 0, 1, 'last'), 3);
% figure(12)
% plot(prz(:,3), prz(:,4))


%% store data for the next stages of processing/output
od.positions = all_positions;
od.responseData = responseData;
od.maxIntensityResponses = maxIntensityResponses;
od.spikeRate_by_spot = spikeRate_by_spot;
od.displayTime = displayTime; 
od.timeOffset = t_offset;
od.centerOfMassXY = centerOfMassXY;
od.farthestResponseDistance = farthestResponseDistance;


end