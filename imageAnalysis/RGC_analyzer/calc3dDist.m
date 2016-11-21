function [strat_x, strat_density, allXYpos, allZpos ,density] = calc3dDist(nodes,edges,medVZmin,medVZmax, Nbins)
% calculate the mass of each edge and assign it to nodes located at the center of each edge
% this is because edges can be 1, sqrt(2), or sqrt(3) units long in 3d
[density,nodes] = segmentLengths(nodes,edges);
% shift the nodes so that the xy center of mass is at the origin
allXYpos = [nodes(:,1)-density'*nodes(:,1)/sum(density) nodes(:,2)-density'*nodes(:,2)/sum(density)];
% rotate the nodes so that the xy component of the longest principal axis coincides with the main diagonal - to save space and computation
%allXYpos = align2dDataWithMainDiagonal([allXYpos nodes(:,3)-density'*nodes(:,3)/sum(density)],density);
% normalize nodes by the SAC surface unit
allZpos = (nodes(:,3) - medVZmin)/(medVZmax - medVZmin);
binEdges = linspace(-2,3,Nbins);
strat_density = zeros(1, Nbins-1);
%keyboard;
for i=1:Nbins-1
    ind = find(allZpos >=  binEdges(i) & allZpos <  binEdges(i+1));
    if ~isempty(ind)
        strat_density(i) = sum(density(ind));
    end
end

strat_x = (binEdges(1:end-1) + binEdges(2:end)) / 2;
