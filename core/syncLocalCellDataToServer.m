function [] = syncLocalCellDataToServer()
global ANALYSIS_FOLDER;
global CELL_DATA_FOLDER
global CELL_DATA_MASTER

if ~(exist(CELL_DATA_MASTER, 'dir') == 7)
    disp('Could not connect to CellDataMaster');
    return;
end

disp('Sync all local cell data to server')

%get all cellData names in local cellData folder
cellDataNames = ls([ANALYSIS_FOLDER filesep 'cellData' filesep '*.mat']);
if ismac
    cellDataNames = strsplit(cellDataNames); %this will be different on windows - see doc ls
elseif ispc
    cellDataNames = cellstr(cellDataNames);
end
cellDataNames = sort(cellDataNames);

% cellDataBaseNames = cell(length(cellDataNames), 1);

for i=1:length(cellDataNames)
    [~, basename, ~] = fileparts(cellDataNames{i});
    if ~isempty(basename)
        fileinfo = dir([CELL_DATA_FOLDER basename '.mat']);
        localModDate = fileinfo.datenum;
        try
            fileinfo = dir([CELL_DATA_MASTER basename '.mat']);
            serverModDate = fileinfo.datenum;
        catch
            serverModDate = 0;
        end
        if localModDate > serverModDate + 60 %more than 60 seconds newer
           fprintf('Found newer local copy of %s, by %d sec. Copying to server...', basename, round(localModDate - serverModDate));
           load([CELL_DATA_FOLDER basename '.mat']); %loads cellData
           saveAndSyncCellData(cellData);
        end
    end
end
