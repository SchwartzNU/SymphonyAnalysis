function tTree = recursiveLabel(tTree, nodeInd, nodeLabel)
%Adam 1/13/15
%Fills in binary alphabetic labels for all nodes recursively

if nodeInd == 1
    nodeLabel = [];
end;
curNode = tTree.get(nodeInd);
if ~tTree.isleaf(nodeInd)
     childInd = tTree.getchildren(nodeInd);
     leftChildInd = min(childInd);
     rightChildInd = max(childInd);
     tTree = recursiveLabel(tTree, leftChildInd, str2double([num2str(nodeLabel),'1']));
     tTree = recursiveLabel(tTree, rightChildInd, str2double([num2str(nodeLabel),'2']));
end;
curNode.id = nodeLabel;
tTree = tTree.set(nodeInd, curNode);

end