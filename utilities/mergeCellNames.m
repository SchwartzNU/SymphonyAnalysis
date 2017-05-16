function cellNames_new = mergeCellNames(cellNames)
global PREFERENCE_FILES_FOLDER;

%read in MergedCells.txt file
fid = fopen([PREFERENCE_FILES_FOLDER 'MergedCells.txt']);
fline = 'temp';
z=1;
mergedCells = {};
while ~isempty(fline)
    fline = fgetl(fid);
    if isempty(fline)
        break;
    end
    if fline == -1
        break;
    end
    mergedCells{z} = {};
    [cname, rem] = strtok(fline);
    mergedCells{z} = [mergedCells{z}; cname];
    while ~isempty(rem)
        [cname, rem] = strtok(rem);
        cname = strtrim(cname);
        %rem = strtrim(rem);
        mergedCells{z} = [mergedCells{z}; cname];
    end
    z=z+1;
end

cellNames_new = cell(length(cellNames), 1);
for i=1:length(cellNames)
    curName = cellDataNameToCellName(mergedCells, cellNames{i});
    cellNames_new{i} = curName;    
end
fclose(fid);
cellNames_new = unique(cellNames_new);