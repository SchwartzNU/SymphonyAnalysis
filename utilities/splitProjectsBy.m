function [] = splitProjectsBy(varargin)
%valid inputs are:
%expDate - splits by experiment
%cellType - splits by cell type
%any cell tag (not epoch properties)
%hasDataSet followed by a second argument specifying the dataSet prefix
%cellTypeWithDataSets followed by a second argument specifying the cell type, a cell array of
%dataSet prefixes, and optional fourth argument of epoch filters for each data
%set
global ANALYSIS_FOLDER;

if exist([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster']) == 7
    cellDataMasterFolder = [filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster'];
else
    disp('Could not connect to CellDataMaster');
    return;
end

if nargin==1
    splitKey = varargin{1};
elseif nargin>1
    splitKey = varargin{1};
    if strcmp(splitKey, 'cellTypeWithDataSets');
        cellTypeName = varargin{2};
        dataSetPrefixList = varargin{3};
        if nargin == 4
            filterList = varargin{4}; %not implemented yet
        else
            filterList = [];
        end
    else
        dataSetPrefix = varargin{2};
    end
else
    disp('Please call with either splitBy argument or hasDataSet and a second argument');
    return;
end

%get all cellData names in CellDataMaster
cellDataNames = ls([cellDataMasterFolder filesep '*.mat']);
cellDataNames = strsplit(cellDataNames); %this will be different on windows - see doc ls
cellDataNames = sort(cellDataNames);

cellDataBaseNames = cell(length(cellDataNames), 1);
z = 1;
for i=1:length(cellDataNames)
    [~, basename, ~] = fileparts(cellDataNames{i});
    if ~isempty(basename)
        cellDataBaseNames{z} = basename;
        z=z+1;
    end
end

L = length(cellDataBaseNames);
projMap = containers.Map;
if strcmp(splitKey, 'expDate');
    for i=1:L
        disp(['Cell ' num2str(i) ' of ' num2str(L)]);
        if ~isempty(cellDataBaseNames{i})
            curExp = strtok(cellDataBaseNames{i}, 'c');
            if projMap.isKey(curExp)
                tempCells = projMap(curExp);
                projMap(curExp) = [tempCells, cellDataBaseNames{i}];
            else
                projMap(curExp) = {cellDataBaseNames{i}};
            end
        end
    end
elseif strcmp(splitKey, 'hasDataSet');
    for i=1:L
        disp(['Cell ' num2str(i) ' of ' num2str(L)]);
        if ~isempty(cellDataBaseNames{i})
            load([cellDataMasterFolder filesep cellDataBaseNames{i}]); %loads cellData
            %check for dataset and add to ProjMap (in this case only one key)
            dataSetNames = cellData.savedDataSets.keys;
            if sum(cell2mat(strfind(dataSetNames, dataSetPrefix))) %if has dataSet with prefix
                disp([dataSetPrefix ' found in cell '  cellDataBaseNames{i}]);
                if projMap.isKey(dataSetPrefix)
                    tempCells = projMap(dataSetPrefix);
                    projMap(dataSetPrefix) = [tempCells, cellDataBaseNames{i}];
                else
                    projMap(dataSetPrefix) = {cellDataBaseNames{i}};
                end
            end
        end
    end
elseif strcmp(splitKey, 'cellTypeWithDataSets');
    for i=1:L
        disp(['Cell ' num2str(i) ' of ' num2str(L)]);
        if ~isempty(cellDataBaseNames{i})
            load([cellDataMasterFolder filesep cellDataBaseNames{i}]); %loads cellData
            %first check for correctCellName
            cellType = cellData.cellType;
            %            cellTypeName
            has2cells = false;
            correctCell = false;
            if strfind(cellType, ';') %two parts
                [cellType1, cellType2] = strtok(cellType, ';');
                cellType2 = cellType2(2:end);
                has2cells = true;
            end
            if has2cells
                if strcmp(cellType1, cellTypeName) || strcmp(cellType2, cellTypeName)
                    correctCell = true;
                end
            else
                if strcmp(cellType, cellTypeName)
                    correctCell = true;
                end
            end
            
            if correctCell
                %check for dataset and add to ProjMap (in this case only one key)
                dataSetNames = cellData.savedDataSets.keys;
                hasAllDataSets = true;
                for j=1:length(dataSetPrefixList)
                    if sum(cell2mat(strfind(dataSetNames, dataSetPrefixList{j}))) %if has dataSet with prefix
                        %do nothing
                    else
                        hasAllDataSets = false;
                    end
                end
                if hasAllDataSets
                    disp(['All data sets found in cell '  cellDataBaseNames{i}]);
                    if projMap.isKey(cellTypeName)
                        tempCells = projMap(cellTypeName);
                        projMap(cellTypeName) = [tempCells, cellDataBaseNames{i}];
                    else
                        projMap(cellTypeName) = {cellDataBaseNames{i}};
                    end
                end
            end
        end
    end
elseif strcmp(splitKey, 'cellType'); %cell type
    for i=1:L
        disp(['Cell ' num2str(i) ' of ' num2str(L)]);
        if ~isempty(cellDataBaseNames{i})
            load([cellDataMasterFolder filesep cellDataBaseNames{i}]); %loads cellData
            %check type
            cellType = cellData.cellType;
            has2cells = false;
            if strfind(cellType, ';') %two parts
               [cellType1, cellType2] = strtok(cellType, ';');
               cellType2 = cellType2(2:end);
               has2cells = true;
            end
            if has2cells
                if projMap.isKey(cellType1)
                    tempCells = projMap(cellType1);
                    projMap(cellType1) = [tempCells, cellDataBaseNames{i}];
                else
                    projMap(cellType1) = {cellDataBaseNames{i}};
                end
                if projMap.isKey(cellType2)
                    tempCells = projMap(cellType2);
                    projMap(cellType2) = [tempCells, cellDataBaseNames{i}];
                else
                    projMap(cellType2) = {cellDataBaseNames{i}};
                end
            else
                if projMap.isKey(cellType)
                    tempCells = projMap(cellType);
                    projMap(cellType) = [tempCells, cellDataBaseNames{i}];
                else
                    projMap(cellType) = {cellDataBaseNames{i}};
                end
            end
        end
        
    end
else %cell tag
    for i=1:L
        disp(['Cell ' num2str(i) ' of ' num2str(L)]);
        if ~isempty(cellDataBaseNames{i})
            load([cellDataMasterFolder filesep cellDataBaseNames{i}]); %loads cellData
            %check tag
            tagVal = cellData.get(splitKey);
            if isnan(tagVal)
                tagVal = 'empty';
            end
            if projMap.isKey(tagVal)
                tempCells = projMap(tagVal);
                projMap(tagVal) = [tempCells, cellDataBaseNames{i}];
            else
                projMap(tagVal) = {cellDataBaseNames{i}};
            end
        end
        
    end
    
end

%do the mergeCells here for each element of projMap
allKeys = projMap.keys;
for i=1:length(allKeys)
    projMap(allKeys{i}) = mergeCellNames(projMap(allKeys{i}));
end

masterFolderName = splitKey;
%do not remake for for cellTypeWithDataSets
if strcmp(splitKey, 'cellTypeWithDataSets')
    if ~exist([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName]) == 7
        mkdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName]);
    end
else %all others, remake master folder
    %remake master folder if needed
    if exist([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName]) == 7
        rmdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName], 's');
        mkdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName]);
    end
end

%write all the cellNames.txt
for i=1:length(allKeys)
    if exist([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i}]) == 7
        rmdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i}], 's')
    end
    mkdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i}])
    fid = fopen([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i} filesep 'cellNames.txt'], 'w');
    curCells = projMap(allKeys{i});
    for j=1:length(curCells)
        if ~isempty(curCells{j})
            fprintf(fid, '%s\n', curCells{j});
        end
    end
    fclose(fid);
end
