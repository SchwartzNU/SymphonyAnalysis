function warpedArbor = calcWarpedArbor_single(nodes,edges,radii,surfaceMapping)
% voxelDim: physical size of voxels in um, 1x3

mappedMinPositions=surfaceMapping.mappedMinPositions;
thisVZminmesh=surfaceMapping.thisVZminmesh; thisx=surfaceMapping.thisx; thisy=surfaceMapping.thisy;
% generate correspondence points for the points on the surfaces
[tmpymesh,tmpxmesh] = meshgrid([thisy(1):thisy(end)],[thisx(1):thisx(end)]);
tmpminmesh = thisVZminmesh(thisx(1):thisx(end),thisy(1):thisy(end));
topInputPos = [tmpxmesh(:) tmpymesh(:) tmpminmesh(:)]; 
topOutputPos = [mappedMinPositions(:,1) mappedMinPositions(:,2) median(tmpminmesh(:))*ones(size(mappedMinPositions,1),1)];
% use the correspondence points to calculate local transforms and use those local transforms to map points on the arbor
nodes = localLSregistration_single(nodes,topInputPos,topOutputPos);
% switch to physical dimensions (in um)
%nodes(:,1) = nodes(:,1)*voxelDim(1); nodes(:,2) = nodes(:,2)*voxelDim(2); nodes(:,3) = nodes(:,3)*voxelDim(3);
% calculate median band positions in z
medVZminmesh = median(tmpminmesh(:));
% return the warped arbor and the corresponding median SAC surface values
warpedArbor.nodes=nodes; warpedArbor.edges=edges; warpedArbor.radii=radii;
warpedArbor.medVZmin=medVZminmesh;