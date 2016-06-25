%% SHAPE MODEL
% Sam Cooler 2016

disp('Running full simulation');


imgDisplay = @(X,Y,d) imagesc(X,Y,flipud(d'));
normg = @(a) ((a+eps) / max(abs(a(:))+eps));
plotGrid = @(row, col, cols) ((row - 1) * cols + col);

plotSubunits = 0;
plotSpatialGraphs = 1;
plotStimulus = 0;
plotOutputCurrents = 1;
plotCellResponses = 1;

%% Setup cell data from ephys

% generate RF map for EX and IN
% import completed maps

load rfmaps_060216Ac2_1032.mat
ephys_data_raw = data;

e_positions = {};
e_voltages = sort(voltages);
e_numVoltages = length(e_voltages);
e_intensities = intensities;
e_numIntensities = length(intensities);
clear voltages
clear intensities
s_voltageLegend = {};
for vi = 1:e_numVoltages
    s_voltageLegend{vi} = num2str(e_voltages(vi));
end
s_voltageLegend = {'ex','in'};
s_voltageLegend{end+1} = 'Combined';


sim_endTime = 2.0;
sim_timeStep = 0.0025;
sim_spaceResolution = 5; % um per point
s_edgelength = 350;%max(cell_rfPositions);
c_extent = 0; % start and make in loop:

T = 0:sim_timeStep:sim_endTime;

% dims for: time, X, Y
sim_dims = round([length(T), s_edgelength / sim_spaceResolution, s_edgelength / sim_spaceResolution]);
e_map = nan * zeros(sim_dims(2), sim_dims(3), e_numVoltages);

ii = 1; % just use first intensity for now
for vi = 1:e_numVoltages
    e_vals(vi,:) = ephys_data_raw(vi, ii, 2);
    pos = ephys_data_raw{vi, ii, 1:2};
    e_positions{vi, ii} = pos; %#ok<*SAGROW>
end

if plotSpatialGraphs
    figure(90);clf;
    set(gcf, 'Name','Spatial Graphs','NumberTitle','off');
    axesSpatialData = tight_subplot(e_numVoltages, 2);
end

X = linspace(-0.5 * sim_dims(2) * sim_spaceResolution, 0.5 * sim_dims(2) * sim_spaceResolution, sim_dims(2));
Y = linspace(-0.5 * sim_dims(3) * sim_spaceResolution, 0.5 * sim_dims(3) * sim_spaceResolution, sim_dims(3));
[mapY, mapX] = meshgrid(Y,X);
distanceFromCenter = sqrt(mapY.^2 + mapX.^2);

                    %  ex  in
shiftsByDimVoltage = [-30,-30;  % x
                      -30,-30]; % y

for vi = 1:e_numVoltages
    
%     c = griddata(e_positions{vi, ii}(:,1), e_positions{vi, ii}(:,2), e_vals{vi,ii,:}, mapX, mapY);
%     e_map(:,:,vi) = c;
    
    % add null corners to ground the spatial map at edges
    positions = vertcat(e_positions{vi, ii}, [X(1),Y(1);X(end),Y(1);X(end),Y(end);X(1),Y(end)]);
    vals = vertcat(e_vals{vi,ii,:}, [0,0,0,0]');
    F = scatteredInterpolant(positions(:,1), positions(:,2), vals,...
        'linear','nearest');
    
    m = F(mapX + shiftsByDimVoltage(1,vi), mapY + shiftsByDimVoltage(2,vi)) * sign(e_voltages(vi));
    m(m < 0) = 0;
    m = m ./ max(m(:));
    e_map(:,:,vi) = m;
%     e_map(:,:,vi) = e_map(:,:,vi) - min(min(e_map(:,:,vi)));

    c_extent = max(c_extent, max(distanceFromCenter(m > 0)));
    
    if plotSpatialGraphs
        axes(axesSpatialData((vi-1)*2+1))
        imgDisplay(X,Y,e_map(:,:,vi))
        title(s_voltageLegend{vi});
        colormap parula
        axis equal
    %     surface(mapX, mapY, zeros(size(mapX)), c)
    end
    
end



% Filter from cell
filter_resampledOn = {};
for vi = 1:e_numVoltages
    filter_resampledOn{vi} = normg(resample(filterOn{vi}, round(1/sim_timeStep), 1000));
end

% subunit locations, using generate positions

c_subunitSpacing = 14;
c_subunitSigma = 12;
c_subunitCenters = generatePositions('triangular', [c_extent, c_subunitSpacing, 0]);
c_numSubunits = size(c_subunitCenters,1);

% subunit RF profile, using gaussian w/ set radius (function)
c_subunitRf = zeros(sim_dims(2), sim_dims(3), c_numSubunits);
for si = 1:c_numSubunits
    center = c_subunitCenters(si,:);
    dmap = sqrt((mapX - center(1)).^2 + (mapY - center(2)).^2);
    rf = exp(-dmap ./ c_subunitSigma);
    rf = rf ./ max(rf(:));
    c_subunitRf(:,:,si) = rf;
end

% calculate connection strength for each subunit, for each voltage
s_subunitStrength = zeros(e_numVoltages, c_numSubunits);
for vi = 1:e_numVoltages
    for si = 1:c_numSubunits

        rfmap = e_map(:,:,vi);
        sumap = c_subunitRf(:,:,si);
        [~,I] = max(sumap(:));
        [x,y] = ind2sub([sim_dims(2), sim_dims(3)], I);
        s_subunitStrength(vi,si) = rfmap(x,y);
    end
end

% remove unconnected subunits
nullSubunits = sum(s_subunitStrength) < eps;

c_subunitRf(:,:,nullSubunits) = [];
s_subunitStrength(:,nullSubunits) = [];
c_numSubunits = size(s_subunitStrength,2);

if plotSpatialGraphs
    for vi = 1:e_numVoltages
        axes(axesSpatialData((vi - 1) * 2 + 2))
    %     imagesc(sum(c_subunitRf, 3))
        d = zeros(sim_dims(2), sim_dims(3));
        for si = 1:c_numSubunits
            d = d + c_subunitRf(:,:,si) * s_subunitStrength(vi,si);
        end
        imgDisplay(X,Y,d)
        axis equal
        title('all subunits scaled by maps')
    end
end

%% Setup simulation
if plotSubunits
    figure(103);clf;
    set(gcf, 'Name','Subunit signals','NumberTitle','off');
    axesSignalsBySubunit = tight_subplot(c_numSubunits, 2);
end
sim_responseSubunitsCombinedByOption = {};

%% Main stimulus change loop

stim_mode = 'movingBar';
numAngles = 6;
stim_barDirections = linspace(0,360,numAngles+1);
stim_barDirections(end) = [];
stim_numOptions = length(stim_barDirections);

stim_barSpeed = 500;
stim_barLength = 300;
stim_barWidth = 150;
stim_moveTime = sim_endTime;
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

            % what a nice thing to find just the right MATLAB function
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


    %% Run simulation

    %% Main loop
    s_lightSubunit = zeros(c_numSubunits, sim_dims(1));
    area = (sim_dims(2) * sim_dims(3));
    for ti = 1:length(T)
        sim_light = squeeze(stim_lightMatrix(ti, :, :));
        
        %% Calculate illumination for each subunit
        for si = 1:c_numSubunits

            lightIntegral = sum(sum(sim_light .* c_subunitRf(:,:,si))) / area;
            s_lightSubunit(si,ti) = lightIntegral;

%             figure(101);
%             subplot(2,1,1)
%             imgDisplay(X,Y,sim_light);
%             colormap gray
%             caxis([0,1])
%             colorbar
%             title(sprintf('stimulus at %.3f sec', curTime));
%             
%             subplot(2,1,2)
%             imagesc(c_subunitRf(:,:,si))
%             title(sim_lightSubunit(si,ti));
%             
%             drawnow
%             pause(.01)

        end
    end
    % end time loop
    
    %% temporal filter each subunit individually
    
    s_responseSubunit = [];
    for si = 1:c_numSubunits

%         a = sim_lightSubunit(si,:);
%         d = diff(a);
%         d(end+1) = 0;
%         d(d < 0) = 0;
%         lightOnNess = cumsum(d);

        for vi = 1:e_numVoltages
            % linear convolution
            convolved = conv(s_lightSubunit(si,:), filter_resampledOn{vi});
            
            % nonlinear effects
%             sel = [];
            if e_voltages(vi) < 0
                sel = convolved > 0;
                s = -1;
            else
                sel = convolved < 0;
                s = 1;
            end
            
            rectified = convolved;
            rectified(sel) = 0;
            
            rectThresh = .005;
            rectMult = 1;
            sel = abs(rectified) > rectThresh;
            nonlin = rectified;
            nonlin(sel) = nonlin(sel) * rectMult;
            
%             figure(109)
%             plot(rectified)
%             hold on
%             plot(nonlin)
%             hold off            
%             pause(0.2)

            s_responseSubunit(si,vi,:) = nonlin(1:sim_dims(1));
            
            if plotSubunits
                % plot individual subunit inputs and outputs
                figure(103);
                clf;
%                 axes(axesSignalsBySubunit(((si - 1) * 2 + vi)))
                hold on
                plot(normg(s_lightSubunit(si,:)));
    %             plot(normg(lightOnNess))       
                plot(normg(filter_resampledOn{vi}))
                plot(normg(convolved));
                plot(normg(rectified));
                plot(normg(nonlin));
                title(sprintf('subunit %d light convolved with filter v = %d', si, e_voltages(vi)))
                hold off
                legend('light','filter','filtered', 'rectified', 'nonlinear')
            end
        end
        
    end
    drawnow
    
    
    %% Multiply subunit response by RF strength (connection subunit to RGC)
    sim_responseSubunitScaledByRf = zeros(size(s_responseSubunit));
    for vi = 1:e_numVoltages
        for si = 1:c_numSubunits
            strength = s_subunitStrength(vi,si);
            sim_responseSubunitScaledByRf(si,vi,:) = strength * s_responseSubunit(si,vi,:);
        end
    end
    

    %% combine current across subunits
    sim_responseSubunitsCombined = [];
    for vi = 1:e_numVoltages
        sim_responseSubunitsCombined(vi,:) = sum(sim_responseSubunitScaledByRf(:,vi,:), 1);
    end
    
    sim_responseSubunitsCombinedByOption{optionIndex} = sim_responseSubunitsCombined;
    
end % end of options and response generation

%% Rescale currents and combine, then extract parameters

if plotOutputCurrents
    figure(102);clf;
    set(gcf, 'Name','Output Currents','NumberTitle','off');
    outputAxes = tight_subplot(stim_numOptions, 1, .01, .001);
end

out_valsByOptions = [];

plot_timeLims = [0.5, 1.7];
ephysScale = 1/750;
combineScale = [4, 1, -.1]; % ex, in, spikes (don't get combined)
% displayScale = [5,2.2];

for optionIndex = 1:stim_numOptions
    
    ang = stim_barDirections(optionIndex);
    % Output scale
    sim_responseSubunitsCombinedScaled = sim_responseSubunitsCombinedByOption{optionIndex};
    for vi = 1:e_numVoltages
        sim_responseSubunitsCombinedScaled(vi,:) = combineScale(vi) * sim_responseSubunitsCombinedScaled(vi,:);
    end
    
    
    % Combine Ex and In
    
    sim_responseCurrent = sum(sim_responseSubunitsCombinedScaled, 1);
    
    out_valsByOptions(optionIndex, 1) = -1*sum(sim_responseCurrent(sim_responseCurrent < 0)) / sim_dims(1);


    % output nonlinearity

    % Display output
    
    timeOffsetSim = 0.15;
    timeOffsetSpikes = -0.4;
    if plotOutputCurrents
        axes(outputAxes(optionIndex));
        
        Tsim = T+timeOffsetSim;
        sel = Tsim > plot_timeLims(1) & Tsim < plot_timeLims(2);
        plot(Tsim(sel), sim_responseSubunitsCombinedScaled(:,sel))

        hold on
        % combined sim
        plot(Tsim(sel), sim_responseCurrent(sel));

        %         sim_response_justTheSpikes = sim_response;
%         sim_response_justTheSpikes(sim_response_justTheSpikes > 0) = 0;
%         area(T+timeOffset, sim_response_justTheSpikes, 'LineStyle','none')
        
        
        % ephys responses (ex, in, spikes)
        if plotCellResponses
            Esel = T > plot_timeLims(1) & T < plot_timeLims(2);
            cell_responses = [];
            for vi = 1:3
                mn = ephysScale * c_responses{vi, c_angles == ang}.mean;
                
                mn = combineScale(vi) * resample(mn, round(1/sim_timeStep), 10000);
                cell_responses(vi,:) = mn;
                if vi < 3
                    plot(T(Esel), mn(Esel))
                else
                    plot(T(Esel) + timeOffsetSpikes, mn(Esel));
                end
            end
        end
        % ephys combined values
        cell_responsesCombined = sum(cell_responses(1:2,:));
        
        plot(T(Esel), cell_responsesCombined(Esel));
        
        title(ang)
    %     xlabel('time')
        xlim(plot_timeLims);
        legend('ex_s','in_s','comb_s','ex_e','in_e','spike_e','comb_e');
%         legend('ex_s','in_s','ex_e','in_e'); 
        
        hold off

        out_valsByOptions(optionIndex, 2) = -1*sum(cell_responsesCombined(cell_responsesCombined < 0)) / sim_dims(1);        
        out_valsByOptions(optionIndex, 3) = -1*sum(cell_responses(3,:)) / sim_dims(1);
    end
    
end
linkaxes(outputAxes)
ylim([-1,.6]*1)

% display combined output over stim options

figure(110);clf;
set(gcf, 'Name','Processed outputs over options','NumberTitle','off');
ordering = [2,3,1];
for ti = ordering
    a = deg2rad(stim_barDirections)';

%     a = stim_barDirections';
    p = out_valsByOptions(:,ti) / max(out_valsByOptions(:));
    p = p ./ mean(p);

    a(end+1) = a(1);
    p(end+1) = p(1);
    polar(a, p)
    hold on
end
hold off
legs = {'sim currents','ephys currents','ephys spikes'};
legend(legs(ordering))
% plot(stim_spotDiams, out_valsByOptions)


%% Cry