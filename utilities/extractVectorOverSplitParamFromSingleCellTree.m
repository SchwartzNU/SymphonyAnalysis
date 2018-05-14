function data = extractVectorOverSplitParamFromSingleCellTree(T, paramNames)
% T is analysis tree
% dataByCell is numCells x 2+numParams array: cellName, splitParam, responseValue1, responseValue2, ...


sT = T.subtree(2);
leafNodes = sT.findleaves;
data = {};

paramNames_typed = {};
for paramIndex = 1:length(paramNames)
    curNode = sT.get(leafNodes(1));
    try
        paramStruct = curNode.(paramNames{paramIndex});
    catch
        continue
    end
        
    paramType = paramStruct.type;
    paramUnits = paramStruct.units;
    if strcmp(paramType, 'byEpoch')
        if strcmp(paramUnits, 's')
            paramNames_typed{paramIndex,1} = [paramNames{paramIndex} '_median'];
        else
            paramNames_typed{paramIndex,1} = [paramNames{paramIndex} '_mean'];
        end
    else
        paramNames_typed{paramIndex,1} = [paramNames{paramIndex} '_value'];
    end
end


for paramIndex = 1:length(paramNames)
    splitValues = zeros(length(leafNodes), 1);
    dataValues = splitValues;
    for j=1:length(leafNodes)
        curNode = sT.get(leafNodes(j));
        splitValues(j) = curNode.splitValue;
        try
            dataValues(j) = curNode.(paramNames_typed{paramIndex});
        catch
            dataValues(j) = nan;
        end
    end
    data(1,1) = {splitValues};
    data(1,1 + paramIndex) = {dataValues};
end
