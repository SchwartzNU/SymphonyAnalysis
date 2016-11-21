function allDataByCell = extractVectorOverSplitParamFromMultiCellTree(T, paramNames)
% T is analysis tree
% dataByCell is numCells x 2+numParams array: cellName, splitParam, responseValue1, responseValue2, ...

allDataByCell = {};

cellTypeNodes = T.getchildren(1);

for cellTypeNode = cellTypeNodes
    cellNodes = T.getchildren(cellTypeNode);

    numCells = length(cellNodes);
    dataByCellByCellType = cell(numCells, 3);

    for ci=1:numCells
        sT = T.subtree(cellNodes(ci));
        cellName = T.get(cellNodes(ci)+1).cellName; % maaaagic addressing
        leafNodes = sT.findleaves;

        if ci==1 %sample first leaf to figure out which kind of parameter
            paramNames_typed = {};
            for paramIndex = 1:length(paramNames)
                curNode = sT.get(leafNodes(1));
                paramStruct = curNode.(paramNames{paramIndex});
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
        end

        for paramIndex = 1:length(paramNames)
            splitValues = zeros(length(leafNodes), 1);
            dataValues = splitValues;
            for j=1:length(leafNodes)
                curNode = sT.get(leafNodes(j));
                splitValues(j) = curNode.splitValue;
                dataValues(j) = curNode.(paramNames_typed{paramIndex});
            end
            dataByCellByCellType(ci,1:2) = {cellName, splitValues};
            dataByCellByCellType(ci,2 + paramIndex) = {dataValues};
        end

    end
    allDataByCell = vertcat(allDataByCell, dataByCellByCellType);
end
