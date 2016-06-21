%% SHAPE MODEL
% Sam Cooler 2016


imgDisplay = @(X,Y,d) imagesc(X,Y,flipud(d'));

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


sim_endTime = 0.8;
sim_timeStep = 0.02;
sim_spaceResolution = 5; % um per point
cell_radius = 250;%max(cell_rfPositions);

T = 0:sim_timeStep:sim_endTime;

% dims for: time, X, Y
sim_dims = round([length(T), cell_radius / sim_spaceResolution * 2, cell_radius / sim_spaceResolution * 2]);
e_map = nan * zeros(sim_dims(2), sim_dims(3), e_numVoltages);

ii = 1; % just use first intensity for now
for vi = 1:e_numVoltages
    e_vals(vi,:) = ephys_data_raw(vi, ii, 2);
    pos = ephys_data_raw{vi, ii, 1:2};
    e_positions{vi, ii} = pos; %#ok<*SAGROW>
end

figure(90);clf;
ha = tight_subplot(e_numVoltages, 1);


X = linspace(-0.5 * sim_dims(2) * sim_spaceResolution, 0.5 * sim_dims(2) * sim_spaceResolution, sim_dims(2));
Y = linspace(-0.5 * sim_dims(3) * sim_spaceResolution, 0.5 * sim_dims(3) * sim_spaceResolution, sim_dims(3));
[mapY, mapX] = meshgrid(Y,X);
for vi = 1:e_numVoltages
    
%     c = griddata(e_positions{vi, ii}(:,1), e_positions{vi, ii}(:,2), e_vals{vi,ii,:}, mapX, mapY);
%     e_map(:,:,vi) = c;
    
    F = scatteredInterpolant(e_positions{vi, ii}(:,1), e_positions{vi, ii}(:,2), e_vals{vi,ii,:},...
        'linear','nearest');
    e_map(:,:,vi) = F(mapX, mapY);
    
    axes(ha(vi))
    imgDisplay(X,Y,e_map(:,:,vi))
    title(e_voltages(vi));
    colorbar
    axis equal
%     surface(mapX, mapY, zeros(size(mapX)), c)

end



% subunit locations, using generate positions

% c_subunitSpacing = 40;
% c_subunitSigma = 10;
% cell_subunitCenters = generatePositions('triangular', [cell_radius, c_subunitSpacing, 0]);
% cell_numSubunits = size(cell_subunitCenters,1);

% subunit RF profile, using gaussian w/ set radius (function)



%% Setup simulation


% sim_space = meshgrid
% convert RF maps to this simulation grid

%% Main stimulus change loop

stim_mode = 'movingBar';
numAngles = 8;
stim_barDirection = linspace(0,360,numAngles+1);
stim_barDirection(end) = [];
stim_numOptions = length(stim_barDirection);

figure(102);clf;
outputAxes = tight_subplot(stim_numOptions, 1);

out_valsByOptions = [];

for optionIndex = 1:stim_numOptions

    %% Setup stimulus
    center = [0,0];

    stim_lightMatrix = zeros(sim_dims);


    if strcmp(stim_mode, 'flashedSpot')
        % flashed spot
        stim_spotDiam = 200;
        stim_spotDuration = 0.2;
        stim_spotStart = 0.1;
        stim_intensity = 0.5;
        stim_spotPosition = [100,100];


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




    elseif strcmp(stim_mode, 'movingBar')

        stim_barSpeed = 1000;
        stim_barLength = 300;
        stim_barWidth = 100;
%         stim_barDirection = 60; % degrees
        stim_moveTime = 0.8;
        stim_intensity = 0.5;

        for ti = 1:sim_dims(1)
            t = T(ti);

            movementVector = stim_barSpeed * [cosd(stim_barDirection(optionIndex)), sind(stim_barDirection(optionIndex))];

            barCenter = center + movementVector * (t - stim_moveTime / 2);

            for xi = 1:sim_dims(2)
                x = X(xi);
                for yi = 1:sim_dims(3)
                    y = Y(yi);

                    val = stim_intensity;

                    % circle shape
                    rad = sqrt((x - barCenter(1))^2 + (y - barCenter(2))^2);
                    if rad < stim_barWidth / 2
                        stim_lightMatrix(ti, xi, yi) = val;
                    end
                end
            end
        end
    end


    %% Run simulation

    figure(101);clf;
    response = [];
    scaled_response = [];

    %% Main loop
    for ti = 1:length(T)
        curTime = T(ti);

    %% Calculate illumination
    %     for si = 1:cell_numSubunits
    %         subunitCenter = cell_subunitCenters(si,:);        

        sim_light = squeeze(stim_lightMatrix(ti, :, :));

        imgDisplay(X,Y,sim_light);
        colormap gray
        caxis([0,1])
        colorbar
        title(sprintf('stimulus at %.3f sec', curTime));
        drawnow

        %% Determine rf response

        for vi = 1:e_numVoltages
            % multiply rf map by stim
            % time filter here later
            rfmap = e_map(:,:,vi);

            response(ti, vi) = sum(sum(sim_light .* rfmap));

            v = e_voltages(vi);
            if v == -60
                M = 1;
            else
                M = .8;
            end
            scaled_response(ti, vi) = M * response(ti, vi);

        end




        %% Combine subunit responses



    end
    % end time loop


    %% Output nonlinearity

    combinedResponse = sum(scaled_response,2);
    
    out_valsByOptions(optionIndex) = sum(combinedResponse(combinedResponse > 0));


    %% Display output
    axes(outputAxes(optionIndex));

    plot(T, scaled_response)

    hold on
    plot(T, combinedResponse);
    hold off

%     title('Whole cell Response')
%     xlabel('time')
    xlim([min(T), max(T)]);
    legend(s_voltageLegend);
    
end

%% display combined output over stim options

figure(110);clf;
a = deg2rad(stim_barDirection);
p = out_valsByOptions ./ max(out_valsByOptions);

a(end+1) = a(1);
p(end+1) = p(1);
polar(a, p)


%% Cry