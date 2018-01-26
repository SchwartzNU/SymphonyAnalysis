function [D_topGenes, uniqueTypes_sorted, NofEach_sorted, allGeneNames] = fullSelectiveExpressionMatrixFromBinary(D_tert, D_orig, cellTypes, geneNames, Ngenes, method)

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
D_orig_sorted = D_orig(:,ind);
D_tert_sorted = D_tert(:,ind);

cellTypes = cellTypes(ind);
targetInd_all = ind;
%make full matrix
D_topGenes = zeros(Ngenes*Ntestable,length(cellTypes));
allGeneNames = [];

curInd = 1;
for i=1:Ntypes
    if NofEach_sorted(i) > 2
        [~, ~, ~, curD, ~, geneNames_sorted] = ...
            selectiveExpressionMatrixFromBinary(D_tert_sorted, D_orig_sorted, cellTypes, geneNames, uniqueTypes_sorted{i}, Ngenes, method);
        D_topGenes(curInd:curInd+Ngenes-1,:) = curD;
        allGeneNames = [allGeneNames; geneNames_sorted]; 
        curInd = curInd+Ngenes;
    end    
end
