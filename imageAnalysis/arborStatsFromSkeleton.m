function arborStats = arborStatsFromSkeleton(nodes, edges)
%nodes is Nnodes x 3 [x,y,z], edges is as in .swc connecting nodes

S.edges = edges;
S.allXYpos = nodes(:,1:2);
S.allZpos = nodes(:,3);

[boundaryPoints, polygonArea] = boundary(S.allXYpos(:,1), S.allXYpos(:,2), 1);
[~, polygonArea_convex] = boundary(S.allXYpos(:,1), S.allXYpos(:,2), 0);
S.polygonArea = polygonArea;
S.boundaryPoints = boundaryPoints;
S.convexityIndex = polygonArea_convex ./ polygonArea;

R = morphologyParams(S);

R.arborDensity =  R.totalLen / S.polygonArea;
                 
arborStats = mergeStruct(R, S);
        