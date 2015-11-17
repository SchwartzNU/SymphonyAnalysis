function od = processShapeData(epochData)
% epochData: cell array of ShapeData

od = struct();

num_epochs = size(epochData, 1);

alignmentTemporalOffset = NaN;

%% create full positions list


all_positions = [];
for p = 1:num_epochs
    col_x = epochData{p}.shapeDataColumns('X');
    col_y = epochData{p}.shapeDataColumns('Y');
    all_positions = vertcat(all_positions, epochData{p}.shapeDataMatrix(:,[col_x col_y])); %#ok<AGROW>
end
all_positions = unique(all_positions, 'rows');
responseData = cell(size(all_positions, 1), 1);

for p = 1:num_epochs
    e = epochData{p};
    od.spotTotalTime = e.spotTotalTime;
    od.spotOnTime = e.spotOnTime;
    od.numSpots = e.numSpots;
        
    col_x = e.shapeDataColumns('X');
    col_y = e.shapeDataColumns('Y');
    col_intensity = e.shapeDataColumns('intensity');
    col_startTime = e.shapeDataColumns('startTime');
    col_endTime = e.shapeDataColumns('endTime');

    epoch_positions = e.shapeDataMatrix(:,[col_x col_y]);
    epoch_intensities = e.shapeDataMatrix(:,col_intensity);
    startTime = e.shapeDataMatrix(:,col_startTime);
    endTime = e.shapeDataMatrix(:,col_endTime);
    

    %% find the time offset from light to spikes, assuming On semi-transient cell
%     lightOnValue = 1.0 * (mod(e.t - e.preTime, e.spotTotalTime) < e.spotOnTime * 1.2);
    t = (e.t - e.preTime);
    lightOnTime = zeros(size(t));
    for si = 1:e.totalNumSpots
        lightOnTime(t > startTime(si) & t < endTime(si)) = epoch_intensities(si);
    end
    % 
%     disp(e.epochMode)
    
    [c,lags] = xcorr(e.spikeRate, lightOnTime);
    lags = lags ./ e.sampleRate;
%     c = c .* (1 - abs(lags' / e.spotTotalTime) * .1); % bias toward low
%     values (just use mod later)
    [~,I] = max(c);
    
    % here be dragons
    % the .05 is to give it a bit of slack early in case some strong
    % responses are making it delay too much
    t_offset = mod(lags(I), e.spotTotalTime) - .05; % - defaultOffset
    
    % pull temporal alignment from temporal alignment epoch if available,
    % or store it now if generated
    if strcmp(e.epochMode, 'temporalAlignment')
        alignmentTemporalOffset = t_offset;
    elseif ~isnan(alignmentTemporalOffset)
        t_offset = alignmentTemporalOffset;
    end
    
    
%     t_offset = 0.1;
    
%     figure(95)
%     clf;
%     hold on
%     plot(lags, c)
%     title('lags')
% %     t_offset = 0.25;
% %     t_basis = e.t + t_offset;
%     
%     figure(96)
%     clf;
%     hold on
%     plot(e.t, e.spikeRate./max(e.spikeRate)*5)
%     plot(e.t, lightOnTime)
%     plot(e.t+t_offset, lightOnTime * .5)

    sampleCount = round(e.spotTotalTime * e.sampleRate);
    displayTime = e.t(1:sampleCount) + t_offset;
    
    spikeRate_by_spot = zeros(e.numSpots, sampleCount);
    
    for si = 1:e.totalNumSpots
        spot_position = epoch_positions(si,:);
        spot_intensity = epoch_intensities(si);
        
        segmentStartIndex = find(e.t > e.spotTotalTime * (si - 1) + t_offset, 1);
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
validSearchResult = 1;

if size(all_positions, 1) < 3 % can't triangulate
    validSearchResult = 0;
end

maxIntensityResponses = zeros(length(responseData), 1);

highestIntensity = -Inf;
% find highest intensity
for p = 1:length(responseData)
    r = responseData{p,1};
    if ~isempty(r)
        highestIntensity = max(max(r(:,1)), highestIntensity);
    end
end

% get the responses at that intensity for simple mapping
for p = 1:length(responseData)
    r = responseData{p,1};
    if ~isempty(r)
        spikes = mean(r(r(:,1) == highestIntensity, 2)); % just get the intensity 1.0 ones
    else
        spikes = 0;
    end
    maxIntensityResponses(p,1) = spikes;
end

centerOfMassXY = [sum(all_positions(:,1) .* maxIntensityResponses)/sum(maxIntensityResponses), ...
                    sum(all_positions(:,2) .* maxIntensityResponses)/sum(maxIntensityResponses)];
if any(isnan(centerOfMassXY(:)))
    validSearchResult = 0;
end

% find the farthest point above a threshold level for autocenter refinement
positions_rel = bsxfun(@plus, all_positions, -1*centerOfMassXY);
distances = sqrt(sum(positions_rel .^ 2, 2));
pos_dist_intensity = [positions_rel, distances, maxIntensityResponses];
pos_dist_intensity = sortrows(pos_dist_intensity, 3); % sort on distances

%TODO: figure out the right threshold for the distance refinement
% max_response = max(simpleResponses);
farthestResponseDistance = pos_dist_intensity(find(pos_dist_intensity(:,4) > 0, 1, 'last'), 3);
if isempty(farthestResponseDistance)
    validSearchResult = 0;
end
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
od.validSearchResult = validSearchResult;


end