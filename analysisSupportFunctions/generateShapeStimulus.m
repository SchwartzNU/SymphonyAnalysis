function runConfig = generateShapeStimulus(mode, parameters, analysisData)

runConfig = struct();
runConfig.autoContinueRun = true;

if isempty(analysisData)
    firstEpoch = true;
    analysisData = struct();
else
    firstEpoch = false;
end

if strcmp(mode, 'autoReceptiveField')
    
    if firstEpoch
        runConfig.epochMode = 'temporalAlignment';
        durations = [1, 0.6, 0.4];
        numSpotsPerRate = 2;
        diam_ta = 100;
        runConfig.shapeDataMatrix = [];
        
        tim = 0;
        for si = 1:numSpotsPerRate
            for dur = durations
                shape = [0, 0, parameters.valueMax, tim, tim + dur / 3, diam_ta];
                runConfig.shapeDataMatrix = vertcat(runConfig.shapeDataMatrix, shape);
                tim = tim + dur;
            end
        end
        %                 obj.stimTimeSaved = round(1000 * (1.0 + tim));
        runConfig.shapeDataColumns = {'X','Y','intensity','startTime','endTime','diameter'};
        runConfig.stimTime = round(1e3 * (1 + tim));
        %                 disp(obj.shapeDataMatrix)
        
    else % standard search
        runConfig.epochMode = 'flashingSpots';
        
        % choose center position and search width
        center = [0,0];
        searchDiameterUpdated = parameters.searchDiameter;
        
        refineCenter = 1;
        if refineCenter && analysisData.validSearchResult == 1
            gfp = analysisData.gaussianFitParams_ooi{3};
            
            center = [gfp('centerX'), gfp('centerY')];
            searchDiameterUpdated = 4 * max([gfp('sigma2X'), gfp('sigma2Y')]) + 1;
        end
        
        % select positions
        positions = generatePositions('random', [parameters.numSpots, parameters.spotDiameter, searchDiameterUpdated / 2]);
        %             positions = generatePositions('grid', [obj.searchDiameter, round(sqrt(obj.numSpots))]);
        
        % add center offset
        positions = bsxfun(@plus, positions, center);
        
        % generate intensity values and repeats
        numSpots = size(positions,1); % in case the generatePositions function is imprecise
        values = linspace(parameters.valueMin, parameters.valueMax, parameters.numValues);
        positionList = zeros(parameters.numValues * numSpots, 3);
        starts = zeros(parameters.numSpots, 1);
        stream = RandStream('mt19937ar');
        
        si = 1; %spot index
        for repeat = 1:parameters.numValueRepeats
            usedValues = zeros(numSpots, parameters.numValues);
            for l = 1:parameters.numValues
                positionIndexList = randperm(stream, numSpots);
                for i = 1:numSpots
                    curPosition = positionIndexList(i);
                    possibleNextValueIndices = find(usedValues(curPosition,:) == 0);
                    nextValueIndex = possibleNextValueIndices(randi(stream, length(possibleNextValueIndices)));
                    
                    positionList(si,:) = [positions(curPosition,:), values(nextValueIndex)];
                    usedValues(curPosition, nextValueIndex) = 1;
                    
                    starts(si) = (si - 1) * parameters.spotTotalTime;
                    
                    si = si + 1;
                end
            end
        end
        diams = parameters.spotDiameter * ones(length(starts), 1);
        ends = starts + parameters.spotOnTime;
        
        %                 obj.stimTimeSaved = round(1000 * (ends(end) + 1.0));
        
        runConfig.shapeDataMatrix = horzcat(positionList, starts, ends, diams);
        runConfig.shapeDataColumns = {'X','Y','intensity','startTime','endTime','diameter'};
        runConfig.stimTime = round(1e3 * (1 + ends(end)));
    end
    
end

if strcmp(mode, 'isoresponse')
    runConfig.epochMode = 'flashingSpots';
    
    % find active spots
    num_positions = size(analysisData.responseData,1);
    validPositionIndices = [];
    values = [];
    for p = 1:num_positions
        responses = analysisData.responseData{p,3};
        valid = any(responses(:,2) > 0);
        if valid
            validPositionIndices = vertcat(validPositionIndices, p);
            values = vertcat(values, responses(:,2));
        end
    end
    
    num_positions = length(validPositionIndices);
    positions = analysisData.positions(validPositionIndices, :);

%         histogram(values, 20);
        
        % find target response value from distribution of response values
    if isfield(analysisData, 'targetIsoValue')
        runConfig.targetIsoValue = analysisData.targetIsoValue;
    else        
        runConfig.targetIsoValue = median(values);
    end
    
    % fit lines to response curves at each spot,
    % find target light intensity
    intensities = [];
    for p = 1:num_positions
        responses = analysisData.responseData{validPositionIndices(p),3};
        responses = sortrows(responses, 1); % order by intensity values for plot
        intensity = responses(:,1);
        value = responses(:,2);
        pfit = polyfit(intensity, value, 1);
        
        targetIntensity = (runConfig.targetIsoValue - pfit(2)) / pfit(1);
        realIntensity = min(max(targetIntensity, .001), 1);
        intensities(p,1) = realIntensity;
    end
    % create shapeMatrix for those intensities
    
    starts = (0:(num_positions-1))' * parameters.spotTotalTime;
    ends = starts + parameters.spotOnTime;
    diams = parameters.spotDiameter * ones(length(starts), 1);
    
    sdm = horzcat(positions, intensities, starts, ends, diams);
    
    runConfig.shapeDataMatrix = [];
    numRepeatsIso = 2; % use averaging in isoresponse 
    for i = 1:numRepeatsIso
        runConfig.shapeDataMatrix = vertcat(runConfig.shapeDataMatrix, sdm);
    end
    
    % shuffle ordering
    ordering = [0;0];
    while any(diff(ordering) == 0) % make sure no repeats
        ordering = randperm(size(runConfig.shapeDataMatrix,1))';
    end
    runConfig.shapeDataMatrix = runConfig.shapeDataMatrix(ordering,:);
    runConfig.shapeDataColumns = {'X','Y','intensity','startTime','endTime','diameter'};
end

end