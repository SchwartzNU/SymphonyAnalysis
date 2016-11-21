function cellDataNames = cellNameToCellDataNames(cellName)

% if isempty(strfind(cellName, '-'))
%     cellDataNames = {cellName};
%     return
% end

cellDataNames = {};
[curName, rem] = strtok(cellName, ',');
curName = strtok(curName, '-Ch');
    
cellDataNames{1} = strtrim(curName);
rem = strtrim(rem);
while ~isempty(rem)
    [curName, rem] = strtok(rem, ',');
    curName = strtok(curName, '-Ch');
    cellDataNames = [cellDataNames; strtrim(curName)];
    rem = strtrim(rem);
end
