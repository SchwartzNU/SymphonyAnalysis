%% Plot frames of stimulus
figure(101);
set(gcf, 'Name','Stimulus Movie Display','NumberTitle','off');
clf;
h = tight_subplot(1,3, .04);
for s = 1:3
    axes(h(s))
    ti = 1 + 240 * (s-1);
    sim_light = squeeze(stim_lightMatrix(ti, :, :));
    plotSpatialData(mapX,mapY,sim_light);
    colormap gray
    caxis([0,1])
    title(sprintf('stimulus at %.3f sec', T(ti)));
    axis square
    axis tight
    drawnow

end


%% Plot Autocenter RF descriptive image (single lit spot)
clf
% spatial plot
spotCenters = generatePositions('triangular', [150, 30, 0]);
numSubunits = size(spotCenters,1);

% add a single circle
i = 10;
stim_spotDiam = 20;
pos = spotCenters(i,:);
display = zeros(size(mapX));
stim_intensity = 0.8;
for xi = 1:sim_dims(2)
    x = X(xi);
    for yi = 1:sim_dims(3)
        y = Y(yi);
        
        val = stim_intensity;
        % circle shape
        rad = sqrt((x - pos(1))^2 + (y - pos(2))^2);
        if rad < stim_spotDiam / 2
            display(xi, yi) = val;
        end
    end
end


plotSpatialData(mapX,mapY,display)
axis equal
hold on
% plot points at the centers of subunits
plot(spotCenters(:,1), spotCenters(:,2),'r.')
colormap gray
axis tight
xlabel('µm')
ylabel('µm')


%% save example autocenter light response to h5
acLightResponse = struct();
ei = 3;

% extract t
acLightResponse.T = ad.epochData{ei}.t;

% light
acLightResponse.Light = ad.epochData{ei}.signalLightOn;

% response
acLightResponse.ResponseE = ad.epochData{ei}.response;
acLightResponse.ResponseI = ad.epochData{ei+1}.response;


delete('acLightResponse.h5');
exportStructToHDF5(acLightResponse, 'acLightResponse.h5', '/');


%% temporal filter extraction

temporalFilter = struct();

% uncomment temporalFilter block in extractFilters

%%

delete('temporalFilter.h5');
exportStructToHDF5(temporalFilter, 'temporalFilter.h5', '/');