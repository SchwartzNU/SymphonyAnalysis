function outputStruct = rgcAnalyzer(arborFileName,image_fname)

[filepath, basename, ~] = fileparts(arborFileName);    
prefsName = fullfile(filepath, [basename '_analysisPrefs.mat']);
CHATsurfName = fullfile(filepath, [basename '_CHATsurface.mat']);

if exist(prefsName, 'file')
    load(prefsName);
else
    %get parameters
    voxelRes_XY = input('Enter XY resolution (microns per pixeL): ');
    voxelRes_Z = input('Enter Z resolution (microns per pixeL): ');
    Nchannels = input('Enter # of channels in image: ');
    CHAT_channel = input('Enter which channel # contains ChAT: ');
    save(prefsName, 'voxelRes_XY', 'voxelRes_Z', 'Nchannels', 'CHAT_channel');
end

conformalJump = 10;
Nbins = 51;
% read the arbor trace file - add 1 to node positions because FIJI format for arbor tracing starts from 0
[nodes,edges,radii,nodeTypes,abort] = readArborTrace(arborFileName,[-1 0 1 2 3 4 5]); 
nodes = nodes + 1;
arborBoundaries(1) = min(nodes(:,1)); arborBoundaries(2) = max(nodes(:,1));
arborBoundaries(3) = min(nodes(:,2)); arborBoundaries(4) = max(nodes(:,2));

if exist(CHATsurfName, 'file')
    load(CHATsurfName);
else
    resampleFactor = 64;
    [X_flat, Y_flat, Z_flat_ON, Z_flat_OFF] = CHAT_analyzer(image_fname, Nchannels, CHAT_channel, resampleFactor, voxelRes_XY);
    save(CHATsurfName, 'X_flat', 'Y_flat', 'Z_flat_ON', 'Z_flat_OFF');
end

thisVZminmesh = fitSurfaceToSACAnnotation_fromPoints(X_flat,Y_flat,Z_flat_ON);
thisVZmaxmesh = fitSurfaceToSACAnnotation_fromPoints(X_flat,Y_flat,Z_flat_OFF);
thisVZminmesh = thisVZminmesh*voxelRes_Z;
thisVZmaxmesh = thisVZmaxmesh*voxelRes_Z;

% find conformal maps of the ChAT surfaces onto the median plane
surfaceMapping = calcWarpedSACsurfaces(thisVZminmesh,thisVZmaxmesh,arborBoundaries,conformalJump);
warpedArbor = calcWarpedArbor(nodes,edges,radii,surfaceMapping);

if warpedArbor.medVZmin > warpedArbor.medVZmax %chat band order reversed
    ON_chat_pos = warpedArbor.medVZmax;
    OFF_chat_pos = warpedArbor.medVZmin;
else
    ON_chat_pos = warpedArbor.medVZmin;
    OFF_chat_pos = warpedArbor.medVZmax;
end

[strat_x, strat_density, allXYpos, allZpos, nodeDensity] = calc3dDist(warpedArbor.nodes,warpedArbor.edges,ON_chat_pos,OFF_chat_pos, Nbins);
strat_y = strat_density*voxelRes_XY; %now in units of microns length
strat_y_norm = strat_y./max(strat_y);
edges = warpedArbor.edges;

h = figure;
basename = strtok(arborFileName, '.');
title(basename);
subplot(1, 2, 1);
plot(strat_x, strat_y);
xlabel('Normalized IPL depth');
ylabel('Dendritic length (microns)');
if ~exist('ON_OFF_division', 'var')
    ON_OFF_division = input('Set ON-OFF stratification division (empty for monostratified cells): ');
    save(prefsName, 'ON_OFF_division', '-append');
end
subplot(1, 2, 2);
if isempty(ON_OFF_division); %monostratified
    scatter(allXYpos(:,1), allXYpos(:,2), 'kx');
else  %bistratified
    ON_ind = find(allZpos<=ON_OFF_division);
    OFF_ind = find(allZpos>ON_OFF_division);
    scatter(allXYpos(ON_ind,1), allXYpos(ON_ind,2), 'gx')
    hold on;
    scatter(allXYpos(OFF_ind,1), allXYpos(OFF_ind,2), 'rx')
    hold off;
    xlabel('microns');
    ylabel('microns');
end

outputStruct.ON_OFF_division = ON_OFF_division;
outputStruct.strat_x = strat_x;
outputStruct.strat_y = strat_y;
outputStruct.strat_y_norm = strat_y_norm;
outputStruct.allXYpos = allXYpos;
outputStruct.allZpos = allZpos;
outputStruct.nodeDensity = nodeDensity;
outputStruct.edges = edges;
close(h);


