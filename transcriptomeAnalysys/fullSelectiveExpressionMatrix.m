function [D_full, uniqueTypes_sorted, NofEach_sorted, allGeneNames, targetInd_all] = fullSelectiveExpressionMatrix(D, cellTypes, geneNames, Ngenes, method, directionPref)
if ~isempty(directionPref)
    for i=1:length(cellTypes)
        if ~strcmp(directionPref{i}, '-')
            cellTypes{i} = [cellTypes{i} ':' directionPref{i}];
        end
    end
end
uniqueTypes = unique(cellTypes);

Ntypes = length(uniqueTypes);
NofEach = zeros(1,Ntypes);
%sort by most prevalent
for i=1:Ntypes
    NofEach(i) = length(find(strcmp(uniqueTypes{i}, cellTypes)));
end
[NofEach_sorted, ind] = sort(NofEach, 'descend');
uniqueTypes_sorted = uniqueTypes(ind);

Ntestable = length(find(NofEach>2));

%sort by type
ind = [];
for i=1:Ntypes
    ind = [ind, find(strcmp(uniqueTypes_sorted{i}, cellTypes))];    
end
%ind
D_sorted = D(:,ind);
cellTypes = cellTypes(ind);
targetInd_all = ind;
%make full matrix
D_full = zeros(Ngenes*Ntestable,length(cellTypes));
allGeneNames = [];

curInd = 1;
for i=1:Ntypes
    if NofEach_sorted(i) > 2
        [~, ~, ~, curD, ~, geneNames_sorted] = ...
            selectiveExpressionMatrix(D_sorted, cellTypes, geneNames, uniqueTypes_sorted{i}, Ngenes, method);
        D_full(curInd:curInd+Ngenes-1,:) = curD;
        allGeneNames = [allGeneNames; geneNames_sorted]; 
        curInd = curInd+Ngenes;
    end    
end