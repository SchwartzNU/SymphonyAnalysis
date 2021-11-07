function surfaceMapping = calcWarpedSurface_single(thisVZminmesh,arborBoundaries,conformalJump)
minXpos = arborBoundaries(1); maxXpos = arborBoundaries(2); minYpos = arborBoundaries(3); maxYpos = arborBoundaries(4);
% retain the minimum grid of SAC points, where grid resolution is determined by conformalJump
thisx = round([max(minXpos-1,1):conformalJump:min(maxXpos+1,size(thisVZminmesh,1))]);
thisy = round([max(minYpos-1,1):conformalJump:min(maxYpos+1,size(thisVZminmesh,2))]);
thisminmesh=thisVZminmesh(thisx,thisy);
% calculate the traveling distances on the diagonals of the two SAC surfaces - this must be changed to Dijkstra's algorithm for exact results
[mainDiagDistMin, skewDiagDistMin] = calculateDiagLength(thisx,thisy,thisminmesh);
% average the diagonal distances on both surfaces for more stability against band tracing errors - not ideal
mainDiagDist = mainDiagDistMin; skewDiagDist = skewDiagDistMin;
% quasi-conformally map individual SAC surfaces to planes
mappedMinPositions = conformalMap_indepFixedDiagonals(mainDiagDist,skewDiagDist,thisx,thisy,thisminmesh);
% align the two independently mapped surfaces so their flattest regions are registered to each other
% return original and mapped surfaces with grid information
surfaceMapping.mappedMinPositions=mappedMinPositions; 
%surfaceMapping.mappedMaxPositions=mappedMaxPositions;
surfaceMapping.thisVZminmesh=thisVZminmesh;
%surfaceMapping.thisVZmaxmesh=thisVZmaxmesh; 
surfaceMapping.thisx=thisx; surfaceMapping.thisy=thisy;
