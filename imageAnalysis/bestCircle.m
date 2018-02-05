function ind = bestCircle(s, r, c, areaThres, solidThres)
ind = [];
centerPoint = round([r/2, c/2]);

L = length(s);

ind_selected = [];
for i=1:L
    if s(i).Area > areaThres && s(i).Solidity > solidThres
        ind_selected = [ind_selected, i];
    end
end

if ~isempty(ind_selected)
    s = s(ind_selected);
    L = length(s);
    for i=1:L
        dist(i) = pdist([centerPoint; s(i).Centroid]);
    end
    
    [~, minInd] = min(dist);
    ind = ind_selected(minInd);
end