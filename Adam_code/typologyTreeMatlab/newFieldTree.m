function sTree = newFieldTree(tTree, infoByNode)
%Adam 1/20/15
%make a new tree out of tTree that has a simple variable at nodes
%with node info given by an array as a parameter
%e.g. number of cells

sTree = tree(tTree,'clear');
for I = 1:length(tTree.Node)
    sTree = sTree.set(I,infoByNode(I));
end;
disp(sTree.tostring);
end