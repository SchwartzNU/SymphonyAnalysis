if plotSubunitCurrents
    figure(103);clf;
    set(gcf, 'Name','Subunit signals','NumberTitle','off');
    axesSignalsBySubunit = tight_subplot(c_numSubunits, 2);
end
sim_responseSubunitsCombinedByOption = {};

% Main stimulus change loop

stim_mode = 'movingBar';
numAngles = 12;
stim_barDirections = linspace(0,360,numAngles+1);
stim_barDirections(end) = [];
% stim_barDirections = [210];
stim_numOptions = length(stim_barDirections);

stim_barSpeed = 500;
stim_barLength = 1000;
stim_barWidth = 200;
stim_moveTime = sim_endTime + 1;
stim_intensity = 0.5;

% stim_mode = 'flashedSpot';
% numSizes = 8;
% stim_spotDiams = logspace(log10(30), log10(1000), numSizes);
% stim_numOptions = length(stim_spotDiams);

% stim_mode = 'flashedSpot';
% stim_numOptions = 1;

%         stim_spotDiam = 200;
% stim_spotDuration = 0.4;
% stim_spotStart = 0.1;
% stim_intensity = 0.5;
% stim_spotPosition = [0,0];

parfor optionIndex = 1:stim_numOptions
    fprintf('Running option %d of %d\n', optionIndex, stim_numOptions);

    %% Setup stimulus
    center = [0,0];

    stim_lightMatrix = zeros(sim_dims);


    if strcmp(stim_mode, 'flashedSpot')
        % flashed spot
        stim_spotDiam = stim_spotDiams(optionIndex);


        pos = stim_spotPosition + center;
        for ti = 1:sim_dims(1)
            t = T(ti);
            if t > stim_spotStart && t < stim_spotStart + stim_spotDuration

                for xi = 1:sim_dims(2)
                    x = X(xi);
                    for yi = 1:sim_dims(3)
                        y = Y(yi);

                        val = stim_intensity;
insert
                        % circle shape
                        rad = sqrt((x - pos(1))^2 + (y - pos(2))^2);
                        if rad < stim_spotDiam / 2
                            stim_lightMatrix(ti, xi, yi) = val; 
                        end
                    end
                end
            end
        end


    elseif strcmp(stim_mode, 'movingBar')

        stim_barDirection = stim_barDirections(optionIndex); % degrees

        
        % make four corner points
        l = stim_barLength / 2;
        w = stim_barWidth / 2;
        corners = [-l,w;l,w;l,-w;-l,-w];
        
        % rotate corners
        theta = stim_barDirection; % not sure if this should be positive or negative... test to confirm
        R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
        for p = 1:size(corners, 1);
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
    end
    
    % plot movie of stimulus
    if plotStimulus
        figure(101);
        set(gcf, 'Name','Stimulus Movie Display','NumberTitle','off');
        clf;
        for ti = 1:length(T)
            sim_light = squeeze(stim_lightMatrix(ti, :, :));
            imgDisplay(X,Y,sim_light);
            colormap gray
            caxis([0,1])
            colorbar
            title(sprintf('stimulus at %.3f sec', T(ti)));

            drawnow
%             pause(sim_timeStep)

        end
    end


    %% Simulation starts here

    %% Run through time to calculate light input signals to each subunit
    s_lightSubunit = zeros(c_numSubunits, sim_dims(1));
    area = (sim_dims(2) * sim_dims(3));
    for ti = 1:length(T)
        sim_light = squeeze(stim_lightMatrix(ti, :, :));
        
        %% Calculate illumination for each subunit
        for si = 1:c_numSubunits

            lightIntegral = sum(sum(sim_light .* c_subunitRf(:,:,si))) / area;
            s_lightSubunit(si,ti) = lightIntegral;

        end
    end
    
    %% temporal filter each subunit individually
    
    % loop through subunits
    s_responseSubunit = [];
    for si = 1:c_numSubunits

%         a = sim_lightSubunit(si,:);
%         d = diff(a);
%         d(end+1) = 0;
%         d(d < 0) = 0;
%         lightOnNess = cumsum(d);

%%      for each subunit & voltage, do a bunch of signal processing

        % todo: swith to different sets of subunits for each input type
        for vi = 1:e_numVoltages
            % linear convolution
            temporalFiltered = conv(s_lightSubunit(si,:), filter_resampledOn{vi});
            
            % nonlinear effects
%             sel = [];
            if e_voltages(vi) < 0
                sel = temporalFiltered > 0;
                s = -1;
            else
                sel = temporalFiltered < 0;
                s = 1;
            end
            
            % rectify and saturate (replace with a hill function)
            rectified = temporalFiltered;
            rectified(sel) = 0;
            
            rectThresh = .005;
            rectMult = 1;
%             saturThresh = .04;
            sel = abs(rectified) > rectThresh;
            nonlin = rectified;
            nonlin(sel) = nonlin(sel) * rectMult;
%             nonlin(abs(nonlin) > saturThresh) = sign(nonlin(abs(nonlin) > saturThresh)) * saturThresh;
            
%             filterTimeConstant = 0.17;
%             filterLength = 0.4; %sec
%             tFilt = 0:sim_timeStep:filterLength;
%             filter_subunitTemporalDecay = exp(-tFilt/tau);
%             filter_subunitTemporalDecay = filter_subunitTemporalDecay ./ sum(filter_subunitTemporalDecay);
%             decayed = conv(nonlin, filter_subunitTemporalDecay, 'same');
%     

            s_responseSubunit(si,vi,:) = nonlin(1:sim_dims(1));
            
            warning('off','MATLAB:legend:IgnoringExtraEntries')

            if plotSubunitCurrents
                % plot individual subunit inputs and outputs
                figure(103);
                clf;
%                 axes(axesSignalsBySubunit(((si - 1) * 2 + vi)))
                hold on
                plot(normg(s_lightSubunit(si,:)));
    %             plot(normg(lightOnNess))       
                plot(normg(filter_resampledOn{vi}))
%                 plot(normg(filter_subunitTemporalDecay));                
                plot(normg(temporalFiltered));
                plot(normg(rectified));
                plot(normg(nonlin));
%                 plot(normg(decayed));
                title(sprintf('subunit %d light convolved with filter v = %d', si, e_voltages(vi)))
                hold off
                legend('light','temporalFilter', 'filtered', 'rectified', 'nonlinear')
            end
        end
        
    end
    drawnow
    
    
    % Multiply subunit response by RF strength (connection subunit to RGC)
    sim_responseSubunitScaledByRf = zeros(size(s_responseSubunit));
    for vi = 1:e_numVoltages
        for si = 1:c_numSubunits
            strength = s_subunitStrength(vi,si);
            sim_responseSubunitScaledByRf(si,vi,:) = strength * s_responseSubunit(si,vi,:);
        end
    end
    

    % combine current across subunits
    sim_responseSubunitsCombined = [];
    for vi = 1:e_numVoltages
        sim_responseSubunitsCombined(vi,:) = sum(sim_responseSubunitScaledByRf(:,vi,:), 1);
    end
    
    sim_responseSubunitsCombinedByOption{optionIndex} = sim_responseSubunitsCombined;
    
end % end of options and response generation
