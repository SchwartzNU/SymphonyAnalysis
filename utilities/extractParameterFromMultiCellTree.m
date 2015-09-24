function paramVec = extractParameterFromMultiCellTree(T, paramName, splitVal)
%T is analysis tree
cellTypeNode = T.getchildren(1);
cellNodes = T.getchildren(cellTypeNode);

L = length(cellNodes);
paramVec = ones(1,L)*nan;


for i=1:L
    sT = T.subtree(cellNodes(i));
    leafNodes = sT.findleaves;
    nLeaves = length(leafNodes);
    
    if i==1 %sample leaf to figure out which kind of parameter
        curNode = sT.get(leafNodes(1));
        paramStruct = curNode.(paramName);
        paramType = paramStruct.type;
        if strcmp(paramType, 'byEpoch')
            paramName = [paramName '_mean'];
        else
            paramName = [paramName '_value'];
        end
    end
    
    if nLeaves == 1
        curNode = sT.get(leafNodes(1));
        paramVec(i) = curNode.(paramName);
    else
        sVal = length(leafNodes);
        for j=1:length(leafNodes)
            curNode = sT.get(leafNodes(j));
            sVal(j) = curNode.splitValue;            
        end
        diffVals = abs(sVal-splitVal);
        [~, bestMatchInd] = min(diffVals);
        curNode = sT.get(leafNodes(bestMatchInd));
        paramVec(i) = curNode.(paramName);        
    end    
end