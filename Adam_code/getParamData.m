function [cellTypeList, numOfCells, cellNamesByType, paramsByType] = getParamData(analysisTree, mainCellType, paramList, cellTypeList)
%'mainCellType' will appear first in the structures.


[cellTypeList, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList);

otherCellTypes = cellTypeList(~strcmp(cellTypeList,mainCellType)); 
numOtherTypes = length(otherCellTypes);
numParams = length(paramList);


%Collect parameter data
paramForMainCellType = cell(1);
paramForOtherTypes = cell(1,numOtherTypes);
N1 = 0; N2 = zeros(numOtherTypes,1);
%cellNamesOtherTypes

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    disp(curCellType);
    if ~isempty( strfind(curCellType, mainCellType))
        curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
        %given cell type, ALL PARAMETERS
        [cellNamesMainType, paramForMainCellType] = allParamsAcrossCells(curCellTypeTree, paramList);
        N1 = length(cellNamesMainType);
    else
        for otherTypeInd = 1:numOtherTypes
            if ~isempty( strfind(curCellType, otherCellTypes{otherTypeInd}))
                curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));               
                [cellNamesOtherTypes{otherTypeInd}, paramForOtherTypes{otherTypeInd}] = allParamsAcrossCells(curCellTypeTree, paramList);
                N2(otherTypeInd) = length(cellNamesOtherTypes{otherTypeInd});
            end;
        end;
    end;
 
end;    

cellNamesByType = [cellNamesMainType; cellNamesOtherTypes];
paramsByType = [paramForMainCellType; paramForOtherTypes];
numOfCells = [N1; N2];
disp(['number of cells: ',num2str(N1+sum(N2))]);

end

