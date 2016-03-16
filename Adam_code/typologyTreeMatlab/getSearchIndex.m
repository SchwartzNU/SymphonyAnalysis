function [nodeIndexToId, nodeIndexToCelltypeList, nodeIndexToConditions] = getSearchIndex(tTree)
%Adam 1/14/15

%Easy search arrays
nodeIndexToId = zeros(length(tTree.Node),1);
nodeIndexToCelltypeList = cell(length(tTree.Node),1);
nodeIndexToConditions = cell(length(tTree.Node),1); 
for I =2:length(tTree.Node)
    nodeIndexToId(I) = tTree.Node{I}.id;
    nodeIndexToCelltypeList{I} = tTree.Node{I}.cellTypeList;
    nodeIndexToConditions{I} = tTree.Node{I}.conditions; 
end;

%root node only celltypeList
nodeIndexToCelltypeList{1} = tTree.Node{1}.cellTypeList;