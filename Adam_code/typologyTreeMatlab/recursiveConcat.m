function [tTree, curNodeList] = recursiveConcat(tTree, nodeInd)
%Adam 1/13/15
%Fills in celltypeList fo all nodes recursively

if tTree.isleaf(nodeInd)
    curNodeList = tTree.Node{nodeInd}.cellTypeList;
else
    childInd = tTree.getchildren(nodeInd);
    curNode = tTree.get(nodeInd);
    [tTree, ch1list] = recursiveConcat(tTree, childInd(1));
    [tTree, ch2list] = recursiveConcat(tTree, childInd(2));
    list1up = [ch1list; ch2list];  %assume binary tree
    list1up = unique(list1up);
    curNode(1).cellTypeList = list1up;
    tTree = tTree.set(nodeInd, curNode);
    curNodeList = list1up;
end;


