function cellName = cellDataNameToCellName(mergedCells, cellDataName) %TODO: this may not work for second and subsequent cells
cellName = cellDataName;
L = length(mergedCells);
for i=1:L
    if sum(strcmp(cellName, mergedCells{i}) > 0)
        if strcmp(cellName, mergedCells{i}{1})
            curMerge = mergedCells{i};
            cellName = curMerge{1};
            for j=2:length(curMerge);
                cellName = [cellName ', ' curMerge{j}];
            end
            break;
        else
            cellName = '';
        end
    end
end
