% shapeModelSetup

sim_endTime = 2.0;
sim_timeStep = 0.005;
sim_spaceResolution = 3; % um per point
s_sidelength = 350;%max(cell_rfPositions);
c_extent = 0; % start and make in loop:

% subunit locations, to generate positions
c_subunitSpacing = [20, 35];
c_subunit2SigmaWidth = [40, 60];
c_subunit2SigmaWidth_surround = [80, 120];
c_subunitSurroundRatio = [0.15, 0.0];

positionOffsetByVoltage = [13,0];

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
    axesSpatialData = tight_subplot(e_numVoltages, 2, .05, .15);
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
    e_map(:,:,vi) = m;
%     e_map(:,:,vi) = e_map(:,:,vi) - min(min(e_map(:,:,vi)));

    c_extent = max(c_extent, max(distanceFromCenter(m > 0)));
    
    if plotSpatialGraphs
        axes(axesSpatialData((vi-1)*2+1))
%         imgDisplay(X,Y,e_map(:,:,vi))
        plotSpatialData(mapX,mapY,e_map(:,:,vi))
%         title(s_voltageLegend{vi});
        colormap parula
        colorbar
        axis equal
        axis tight
%         xlabel('µm')
%         ylabel('µm')
    %     surface(mapX, mapY, zeros(size(mapX)), c)
    end
    
end


% Import temporal filter from cell & resample
filter_resampledOn = {};
for vi = 1:e_numVoltages
    filter_resampledOn{vi} = normg(resample(filterOn{vi}, round(1/sim_timeStep), 1000));
    filter_resampledOn{vi}(end) = -1*sum(filter_resampledOn{vi}(1:end-1));
end

c_subunitSigma = c_subunit2SigmaWidth / 2;
c_subunitSigma_surround = c_subunit2SigmaWidth_surround / 2;
c_subunitCenters = {};
for vi = 1:2
    c_subunitCenters{vi} = generatePositions('triangular', [c_extent, c_subunitSpacing(vi), 0]);
    c_numSubunits(vi) = size(c_subunitCenters{vi},1);
end

% subunit RF profile, using gaussian w/ set radius (function)
c_subunitRf = {};
for vi = 1:2
    c_subunitRf{vi} = zeros(sim_dims(2), sim_dims(3), c_numSubunits(vi));
    for si = 1:c_numSubunits(vi)
        center = c_subunitCenters{vi}(si,:);
        dmap = (mapX - center(1)).^2 + (mapY - center(2)).^2; % no sqrt, so
        rf_c = exp(-(dmap / (2 * c_subunitSigma(vi) .^ 2))); % no square
        rf_s = exp(-(dmap / (2 * c_subunitSigma_surround(vi) .^ 2))); % no square

        rf = rf_c - c_subunitSurroundRatio(vi) * rf_s;
        rf = rf ./ max(rf(:));
        c_subunitRf{vi}(:,:,si) = rf;
    end
end

% calculate connection strength for each subunit, for each voltage
s_subunitStrength = {};
for vi = 1:e_numVoltages
    s_subunitStrength{vi} = zeros(c_numSubunits(vi),1);
    for si = 1:c_numSubunits(vi)

        rfmap = e_map(:,:,vi);
        sumap = c_subunitRf{vi}(:,:,si);
        [~,I] = max(sumap(:));
        [x,y] = ind2sub([sim_dims(2), sim_dims(3)], I);
        
        s_subunitStrength{vi}(si) = rfmap(x,y);
        
%         todo: change it to a regression between map and each subunit as a predictor
%         s_subunitStrength{vi}(si) = sum(rfmap(:) ./ sumap(:));
    end
end

% remove unconnected subunits
for vi = 1:e_numVoltages
    nullSubunits = s_subunitStrength{vi} < eps+.1;
    c_subunitRf{vi}(:,:,nullSubunits) = [];
    s_subunitStrength{vi}(nullSubunits) = [];
    c_subunitCenters{vi}(nullSubunits',:) = [];
    c_numSubunits(vi) = size(s_subunitStrength{vi},1);
end

% plot the spatial graphs
if plotSpatialGraphs
    for vi = 1:e_numVoltages
        axes(axesSpatialData((vi - 1) * 2 + 2))
    %     imagesc(sum(c_subunitRf, 3))
        d = zeros(sim_dims(2), sim_dims(3));
        for si = 1:c_numSubunits(vi)
            d = d + c_subunitRf{vi}(:,:,si) * s_subunitStrength{vi}(si);
        end
        plotSpatialData(mapX,mapY,d)
        axis equal
        axis tight
%         title('all subunits scaled by maps')
        hold on
%         xlabel('µm')
%         ylabel('µm')        
        % plot points at the centers of subunits
        plot(c_subunitCenters{vi}(:,1), c_subunitCenters{vi}(:,2),'r.')
        
    end
end
drawnow