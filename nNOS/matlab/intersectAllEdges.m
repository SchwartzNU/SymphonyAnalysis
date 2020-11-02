function [allPoints,pairedInd] = intersectAllEdges(e1,e2)

% for each e2, store that value along with the index of each intersect
% go back through for each e1, storing value along with index
% combine
allPoints = [];
N = size(e2,1);
pairedInd=[];
for i=1:N
    e1ind{i}=[];
    curP = intersectEdges(e1, e2(i,:));    
    [x, ~] = ind2sub(size(curP), find(~isnan(curP)));   
    ind = unique(x);
    if ~isempty(ind)
        allPoints = cat(1,allPoints, curP(ind, :));
        pairedInd=cat(1,pairedInd,[ind i*ones(size(ind))]);
    end
end