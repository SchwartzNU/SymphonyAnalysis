function [] = splitProjectsBy(varargin)
%valid inputs are:
%expDate - splits by experiment
%cellType - splits by cell type
%any cell tag (not epoch properties)
%hasDataSet followed by a second argument specifying the dataSet prefix
global ANALYSIS_FOLDER;

if exist([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster']) == 7
    cellDataMasterFolder = [filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster'];
else
    disp('Could not connect to CellDataMaster');
    return;
end

if nargin==1
    splitKey = varargin{1};
elseif nargin==2
    splitKey = varargin{1};
    dataSetPrefix = varargin{2};
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
%make master folder if needed
if exist([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName]) ~= 7
    mkdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName]);
end

%write all the cellNames.txt
for i=1:length(allKeys)
    if exist([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i}]) ~= 7
        mkdir([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i}])
    end
    fid = fopen([ANALYSIS_FOLDER filesep 'Projects' filesep masterFolderName filesep allKeys{i} filesep 'cellNames.txt'], 'w');
    curCells = projMap(allKeys{i});
    for j=1:length(curCells)
        if ~isempty(curCells{j})
            fprintf(fid, '%s\n', curCells{j});
        end
    end
    fclose(fid);
end
