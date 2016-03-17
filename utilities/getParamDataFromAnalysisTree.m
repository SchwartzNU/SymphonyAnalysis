function [cellTypeList, numOfCells, cellNamesByType, paramList, paramByType] = getParamDataFromAnalysisTree(analysisTree, paramList, cellTypeList)
%1/23/15 Adam, revised extraction of the data from analysis trees.
%Previously done in 'paramOverlapMany' 
%'mainCellType' will appear first in the structures.


[cellTypeList, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList);

numTypes = length(cellTypeList);
numParams = length(paramList);


%Collect parameter data
paramByType = cell(numTypes,1);
N = zeros(numTypes,1);
%cellNamesOtherTypes

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeIndAnalysisTree = 1:length(cellTypeNodes)
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeIndAnalysisTree)}.name;
    %disp(curCellType);

    cellTypeIndCTlist = getnameidx(cellTypeList, curCellType); 
    if cellTypeIndCTlist~=0
        curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeIndAnalysisTree));
        [cellNamesByType{cellTypeIndCTlist}, ~, paramByType{cellTypeIndCTlist}] = allParamsAcrossCells(curCellTypeTree, paramList);
        N(cellTypeIndCTlist) = length(cellNamesByType{cellTypeIndCTlist});
    end;


end;    

numOfCells = N;
%disp(['number of cells: ',num2str(sum(N))]);

end

