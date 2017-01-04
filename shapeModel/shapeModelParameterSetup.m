% shapeModelSetup

sim_endTime = 5.0;
sim_timeStep = 0.005;
sim_spaceResolution = 3; % um per point
s_sidelength = 350;%max(cell_rfPositions);
c_extent = 0; % start and make in loop:

% subunit locations, to generate positions
c_subunitSpacing = [20 20; 35 35];
c_subunit2SigmaWidth = [40 40; 60 60;];
c_subunit2SigmaWidth_surround = [80 80; 120 120];
c_subunitSurroundRatio = [0.15 0.15; 0.0 0.0];

positionOffsetByVoltage = [paramValues(paramSetIndex,col_rfOffset),0];

% generate RF map for EX and IN
% import completed maps 

load(sprintf('rfmaps_%s_%s.mat', cellName, acName));
ephys_data_raw = data;
    

%% Setup cell data from ephys

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

T = 0:sim_timeStep:sim_endTime;

% dims for: time, X, Y
sim_dims = round([length(T), s_sidelength / sim_spaceResolution, s_sidelength / sim_spaceResolution]);
e_map = nan * zeros(sim_dims(2), sim_dims(3), e_numVoltages, 2);

ii = 1; % just use first intensity for now
for vi = 1:e_numVoltages
    e_vals(vi,:) = ephys_data_raw(vi, ii, 2);
    pos = ephys_data_raw{vi, ii, 1:2};
    e_positions{vi, ii} = pos; %#ok<*SAGROW>
end

if plotSpatialGraphs
    figure(90);clf;
    set(gcf, 'Name','Spatial Graphs','NumberTitle','off');
    axesSpatialData = tight_subplot(e_numVoltages, 3, .05, .15);
end

X = linspace(-0.5 * sim_dims(2) * sim_spaceResolution, 0.5 * sim_dims(2) * sim_spaceResolution, sim_dims(2));
Y = linspace(-0.5 * sim_dims(3) * sim_spaceResolution, 0.5 * sim_dims(3) * sim_spaceResolution, sim_dims(3));
[mapY, mapX] = meshgrid(Y,X);
distanceFromCenter = sqrt(mapY.^2 + mapX.^2);

                    %  ex  in
% shiftsByDimVoltage = [-30,-30;  % x
%                       -30,-30]; % y
% shiftsByDim = analysisData.positionOffset;
% positionOffset = paramValues{paramSetIndex,col_positionOffset};

for vi = 1:e_numVoltages
    for oi = 1:2
    
    %     c = griddata(e_positions{vi, ii}(:,1), e_positions{vi, ii}(:,2), e_vals{vi,ii,:}, mapX, mapY);
    %     e_map(:,:,vi) = c;

        % add null corners to ground the spatial map at edges
        if useRealRf
            positions = e_positions{vi, ii};
            positions = bsxfun(@plus, positions, [0,positionOffsetByVoltage(vi)]);
            vals = e_vals{vi,ii,:};
        %     positions = vertcat(positions, [X(1),Y(1);X(end),Y(1);X(end),Y(end);X(1),Y(end)]);
        %     vals = vertcat(vals, [0,0,0,0]');
            F = scatteredInterpolant(positions(:,1), positions(:,2), vals,...
                'linear','none');
            m = F(mapX, mapY) * sign(e_voltages(vi));    
        else
            d = sqrt((mapY-positionOffsetByVoltage(vi)).^2 + mapX.^2);
            m = -20 + 100*exp(-d.^2 / 80^2);
        end

        m(isnan(m)) = 0;
        m(m < 0) = 0;
        m = m ./ max(m(:));
        e_map(:,:,vi,oi) = m;
    %     e_map(:,:,vi) = e_map(:,:,vi) - min(min(e_map(:,:,vi)));

        c_extent = max(c_extent, max(distanceFromCenter(m > 0)));

        if plotSpatialGraphs
            axes(axesSpatialData((vi-1)*3+1))
    %         imgDisplay(X,Y,e_map(:,:,vi))
            plotSpatialData(mapX,mapY,e_map(:,:,vi))
    %         title(s_voltageLegend{vi});
            colormap parula
            colorbar
            axis equal
            axis tight
            title('cell RF')
    %         xlabel('µm')
    %         ylabel('µm')
        %     surface(mapX, mapY, zeros(size(mapX)), c)
        end
    end
end


