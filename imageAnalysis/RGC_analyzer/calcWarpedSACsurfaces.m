function surfaceMapping = calcWarpedSACsurfaces(thisVZminmesh,thisVZmaxmesh,arborBoundaries,conformalJump)
minXpos = arborBoundaries(1); maxXpos = arborBoundaries(2); minYpos = arborBoundaries(3); maxYpos = arborBoundaries(4);
% retain the minimum grid of SAC points, where grid resolution is determined by conformalJump
thisx = round([max(minXpos-1,1):conformalJump:min(maxXpos+1,size(thisVZmaxmesh,1))]);
thisy = round([max(minYpos-1,1):conformalJump:min(maxYpos+1,size(thisVZmaxmesh,2))]);
thisminmesh=thisVZminmesh(thisx,thisy); thismaxmesh=thisVZmaxmesh(thisx,thisy);
% calculate the traveling distances on the diagonals of the two SAC surfaces - this must be changed to Dijkstra's algorithm for exact results
[mainDiagDistMin, skewDiagDistMin] = calculateDiagLength(thisx,thisy,thisminmesh);
[mainDiagDistMax, skewDiagDistMax] = calculateDiagLength(thisx,thisy,thismaxmesh);
% average the diagonal distances on both surfaces for more stability against band tracing errors - not ideal
mainDiagDist = (mainDiagDistMin+mainDiagDistMax)/2; skewDiagDist = (skewDiagDistMin+skewDiagDistMax)/2;
% quasi-conformally map individual SAC surfaces to planes
mappedMinPositions = conformalMap_indepFixedDiagonals(mainDiagDist,skewDiagDist,thisx,thisy,thisminmesh);
mappedMaxPositions = conformalMap_indepFixedDiagonals(mainDiagDist,skewDiagDist,thisx,thisy,thismaxmesh);
% align the two independently mapped surfaces so their flattest regions are registered to each other
xborders = [thisx(1) thisx(end)]; yborders = [thisy(1) thisy(end)];
mappedMaxPositions = alignMappedSurfaces(thisVZminmesh,thisVZmaxmesh,mappedMinPositions,mappedMaxPositions,xborders,yborders,conformalJump);
% return original and mapped surfaces with grid information
surfaceMapping.mappedMinPositions=mappedMinPositions; surfaceMapping.mappedMaxPositions=mappedMaxPositions;
surfaceMapping.thisVZminmesh=thisVZminmesh; surfaceMapping.thisVZmaxmesh=thisVZmaxmesh; surfaceMapping.thisx=thisx; surfaceMapping.thisy=thisy;
