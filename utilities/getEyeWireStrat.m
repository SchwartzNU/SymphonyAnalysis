function [Xvals, Smat] = getEyeWireStrat(clusters, strat, cellType)
S = strat(clusters(cellType));

L = length(S);
Npnts = length(S{1}(:,1));
Smat = zeros(Npnts,L);

for i=1:L
    if i==1
        Xvals = S{1}(:,1);
    end
    Smat(:,i) = S{i}(:,2);    
end