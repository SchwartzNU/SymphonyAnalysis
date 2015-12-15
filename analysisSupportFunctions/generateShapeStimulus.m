function runConfig = generateShapeStimulus(mode, parameters, analysisData)

parameters = struct();


if isempty(analysisData)
    firstEpoch = true;
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
        parameters.numSpots = size(positions,1); % in case the generatePositions function is imprecise
        values = linspace(parameters.valueMin, parameters.valueMax, parameters.numValues);
        positionList = zeros(parameters.numValues * parameters.numSpots, 3);
        starts = zeros(parameters.numSpots, 1);
        stream = RandStream('mt19937ar');
        
        si = 1; %spot index
        for repeat = 1:parameters.numValueRepeats
            usedValues = zeros(parameters.numSpots, parameters.numValues);
            for l = 1:parameters.numValues
                positionIndexList = randperm(stream, parameters.numSpots);
                for i = 1:parameters.numSpots
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

end