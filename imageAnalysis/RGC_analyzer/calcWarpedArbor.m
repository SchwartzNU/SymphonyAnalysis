function warpedArbor = calcWarpedArbor(nodes,edges,radii,surfaceMapping,voxelDim,conformalJump)
% voxelDim: physical size of voxels in um, 1x3

mappedMinPositions=surfaceMapping.mappedMinPositions; mappedMaxPositions=surfaceMapping.mappedMaxPositions;
thisVZminmesh=surfaceMapping.thisVZminmesh; thisVZmaxmesh=surfaceMapping.thisVZmaxmesh; thisx=surfaceMapping.thisx; thisy=surfaceMapping.thisy;
% generate correspondence points for the points on the surfaces
[tmpymesh,tmpxmesh] = meshgrid([thisy(1):thisy(end)],[thisx(1):thisx(end)]);
tmpminmesh = thisVZminmesh(thisx(1):thisx(end),thisy(1):thisy(end)); tmpmaxmesh = thisVZmaxmesh(thisx(1):thisx(end),thisy(1):thisy(end));
topInputPos = [tmpxmesh(:) tmpymesh(:) tmpminmesh(:)]; botInputPos = [tmpxmesh(:) tmpymesh(:) tmpmaxmesh(:)];
topOutputPos = [mappedMinPositions(:,1) mappedMinPositions(:,2) median(tmpminmesh(:))*ones(size(mappedMinPositions,1),1)];
botOutputPos = [mappedMaxPositions(:,1) mappedMaxPositions(:,2) median(tmpmaxmesh(:))*ones(size(mappedMaxPositions,1),1)];
% use the correspondence points to calculate local transforms and use those local transforms to map points on the arbor
nodes = localLSregistration(nodes,topInputPos,botInputPos,topOutputPos,botOutputPos);
% switch to physical dimensions (in um)
%nodes(:,1) = nodes(:,1)*voxelDim(1); nodes(:,2) = nodes(:,2)*voxelDim(2); nodes(:,3) = nodes(:,3)*voxelDim(3);
% calculate median band positions in z
medVZminmesh = median(tmpminmesh(:)); medVZmaxmesh = median(tmpmaxmesh(:));
% return the warped arbor and the corresponding median SAC surface values
warpedArbor.nodes=nodes; warpedArbor.edges=edges; warpedArbor.radii=radii;
warpedArbor.medVZmin=medVZminmesh; warpedArbor.medVZmax=medVZmaxmesh;
