
% stim_mode = 'movingBar';
% numAngles = 12;
% stim_directions = linspace(0,360,numAngles+1);
% stim_directions(end) = [];
% stim_numOptions = length(stim_directions);
% 
% stim_barSpeed = paramValues(paramSetIndex,col_barSpeed);
% stim_barLength = 500;
% stim_barWidth = 150;
% stim_moveTime = sim_endTime + 1.0;
% stim_intensity = 0.5;

stim_mode = 'flashedEdge';
% stim_edgeSpacing = 20;
% stim_positions = [-120, -90, -60, -30, 0, 30, 60, 90, 120];
% stim_positions = linspace(-130, 130, 12);
stim_positions = [140];

stim_numOptions = length(stim_positions);
stim_edgeAngle = paramValues(paramSetIndex, col_edgeAngle);
stim_contrastSide1 = 1;
stim_contrastSide2 = 0;
% stim_meanLevel = 1; % assume the mean is constant and equal to 1
stim_startTime = 0.01;
stim_stimTime = 0.3;
stim_fullField = 1;

% SMS
% stim_mode = 'flashedSpot';
% numSizes = 8;
% stim_spotDiams = logspace(log10(30), log10(1000), numSizes);
% stim_numOptions = length(stim_spotDiams);


% stim_mode = 'flashedSpot';
% stim_numOptions = 1;
% 
% stim_spotDiam = 200;
% stim_spotDuration = 1;
% stim_spotStart = 0.5;
% stim_intensity = 0.5;
% stim_spotPosition = [0,0];

% stim_mode = 'driftingTexture';
% numAngles = 9;
% stim_directions = linspace(0,360,numAngles+1);
% stim_directions(end) = [];
% stim_numOptions = length(stim_directions);
% 
% stim_texSpeed = 500;
% stim_moveTime = sim_endTime + 1.0;
% stim_meanLevel = 0.5;
% stim_uniformDistribution = 1;
% stim_resScaleFactor = 2;
% stim_randomSeed = 1;
% stim_textureScale = 30;
% stim_movementDelay = 0.5;

stim_lightMatrix_byOption = {};

for optionIndex = 1:stim_numOptions

    %% Setup stimulus
    center = [0,0];

    stim_lightMatrix = zeros(sim_dims); %#ok<*PFTUS>
    % stim_lightMatrix_byOptions = cell(num

    if strcmp(stim_mode, 'flashedSpot')
        % flashed spot
        %         stim_spotDiam = stim_spotDiams(optionIndex);


        pos = stim_spotPosition + center;
        for ti = 1:sim_dims(1)
            t = T(ti);
            if t > stim_spotStart && t < stim_spotStart + stim_spotDuration

                for xi = 1:sim_dims(2)
                    x = X(xi);
                    for yi = 1:sim_dims(3)
                        y = Y(yi);

                        val = stim_intensity;
                        % circle shape
                        rad = sqrt((x - pos(1))^2 + (y - pos(2))^2);
                        if rad < stim_spotDiam / 2
                            stim_lightMatrix(ti, xi, yi) = val;
                        end
                    end
                end
            end
        end

    elseif strcmp(stim_mode, 'flashedEdge')
        if paramValues(paramSetIndex, col_edgeFlip) == 0
            c1 = stim_contrastSide1;
            c2 = stim_contrastSide2;
        else
            c1 = stim_contrastSide2;
            c2 = stim_contrastSide1;
        end
        if stim_fullField
            for ti = 1:sim_dims(1)
                t = T(ti);
                if t > stim_startTime && t < stim_startTime + stim_stimTime
                    
                    if stim_edgeAngle == 0
                        for yi = 1:sim_dims(3)
                            y = Y(yi);
                            if y > stim_positions(optionIndex)
                                stim_lightMatrix(ti, :, yi) = c1;
                            else
                                stim_lightMatrix(ti, :, yi) = c2;
                            end
                        end
                    elseif stim_edgeAngle == 90
                        for xi = 1:sim_dims(2)
                            x = X(xi);
                            if x > stim_positions(optionIndex)
                                stim_lightMatrix(ti, xi, :) = c1;
                            else
                                stim_lightMatrix(ti, xi, :) = c2;
                            end
                        end
                    end
                end
            end        
        else
            error('no non full field code yet')
        end

    elseif strcmp(stim_mode, 'movingBar')

        stim_barDirection = stim_directions(optionIndex); % degrees


        % make four corner points
        l = stim_barLength / 2;
        w = stim_barWidth / 2;
        corners = [-l,w;l,w;l,-w;-l,-w];

        % rotate corners
        theta = stim_barDirection; % not sure if this should be positive or negative... test to confirm
        R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
        for p = 1:size(corners, 1)
            corners(p,:) = (R * corners(p,:)')';
        end


        % translate corners
        movementVector = stim_barSpeed * [cosd(stim_barDirection), sind(stim_barDirection)];
        for ti = 1:sim_dims(1)

            barCenter = center + movementVector * (T(ti) - stim_moveTime / 2);
            cornersTranslated = bsxfun(@plus, corners, barCenter);

            % what a nice thing to find just the right MATLAB function #blessed
            stim_lightMatrix(ti,:,:) = inpolygon(mapX, mapY, cornersTranslated(:,1), cornersTranslated(:,2));

        end


    elseif strcmp(stim_mode, 'driftingTexture')
        direction = stim_directions(optionIndex);
        canvasSize = sim_dims(2:3);
        sigmaPix = 0.5 * (stim_textureScale / sim_spaceResolution);
        distPix = (stim_texSpeed/sim_spaceResolution) * stim_moveTime; % um / sec
        moveDistance = distPix;
        res = [max(canvasSize) * 1.42,...
            max(canvasSize) * 1.42 + distPix]; % pixels
        res = round(res);

        stream = RandStream('mt19937ar','Seed',stim_randomSeed);
        M = randn(stream, res);
        defaultSize = 2*ceil(2*sigmaPix)+1;
        M = imgaussfilt(M, sigmaPix, 'FilterDomain','frequency','FilterSize',defaultSize*2+1);


        if stim_uniformDistribution
            bins = [-Inf prctile(M(:),1:1:100)];
            M_orig = M;
            for i=1:length(bins)-1
                M(M_orig>bins(i) & M_orig<=bins(i+1)) = i*(1/(length(bins)-1));
            end
            M = M - min(M(:)); %set mins to 0
            M = M./max(M(:)); %set max to 1;
            M = M - mean(M(:)) + 0.5; %set mean to 0.5;
        else % normal distribution
            M = zscore(M(:)) * 0.3 + 0.5;
            M = reshape(M, res);
            M(M < 0) = 0;
            M(M > 1) = 1;
        end

        for ti = 1:sim_dims(1)
            if T(ti) < stim_movementDelay
                tMove = 0;
            else
                tMove = T(ti) - stim_movementDelay;
            end
            translation = (stim_texSpeed/sim_spaceResolution) * (tMove - stim_moveTime / 2);    
            M_translate = imtranslate(M, [translation, 0]);
            M_rot = imrotate(M_translate, direction - 90);

            extend = floor(sim_dims(2:3)/2);
            x = (-extend(1):extend(1)) + round(size(M_rot,1)/2);
            y = (-extend(2):extend(2)) + round(size(M_rot,2)/2);
            stim_lightMatrix(ti,:,:) = M_rot(x,y);
        end

    end

    stim_lightMatrix_byOption{optionIndex} = stim_lightMatrix;
end

% plot movie of stimulus
if plotStimulus
    figure(101);
    set(gcf, 'Name','Stimulus Movie Display','NumberTitle','off');
    clf;
    for ti = 1:length(T)
        sim_light = squeeze(stim_lightMatrix(ti, :, :));
        plotSpatialData(mapX,mapY,sim_light);
        colormap gray
        caxis([-2,2])
        colorbar
        title(sprintf('stimulus at %.3f sec', T(ti)));
        axis tight
        drawnow
        %             pause(sim_timeStep)
        
    end
end