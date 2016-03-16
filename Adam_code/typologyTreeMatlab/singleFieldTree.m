function sTree = singleFieldTree(tTree, fieldName)
%Adam 1/15/15
%make a new tree out of tTree that has a simple variable at nodes
%with given field

sTree = tree(tTree,'clear');
for I = 1:length(tTree.Node)
    sTree = sTree.set(I,tTree.Node{I}.(fieldName));
end;
disp(sTree.tostring);
end