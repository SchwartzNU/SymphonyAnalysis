function [] = checkoutCellDataForRawData(expname)
global CELL_DATA_FOLDER;
global CELL_DATA_MASTER;
global RAW_DATA_FOLDER;

%% Check connection to Server
if ~exist(CELL_DATA_MASTER,'dir')
    error('Could not connect to CellDataMaster')
else
    disp('Connected to server verified')
end

%% Choose a raw data file if no experiment day is given
if nargin == 0
    expname = uigetfile([RAW_DATA_FOLDER,'*.h5'], 'Choose raw data file');
    expname = erase(expname,'.h5');
end

%% Look for cellData on server that matched the experiment day
disp('Looking for matching cellData in CellDataMaster')
CellData_Master = dir([CELL_DATA_MASTER,expname,'*']);

if length(CellData_Master) < 1
    disp('No matching cell data found on server')
else
    fprintf('%d matching files found on the server \n', length(CellData_Master))
end

%% Check for any local cellData that is already on your computer for this experiment.
disp('Checking your local Cell Data Folder')
CellData_Local = dir([CELL_DATA_FOLDER,expname,'*']);
CellData_LocalNames = struct2cell(CellData_Local);
CellData_LocalNames = CellData_LocalNames(1,:);
fprintf('%d matching files found locally \n', length(CellData_LocalNames))

%% Copy over cellData from the server that matched the experiment and is not already in your local folder.
for i = 1:length(CellData_Master)
    if any(strcmp(CellData_LocalNames, CellData_Master(i).name))
        fprintf('%s is already in your local cellData \n', CellData_Master(i).name)
    else
        fprintf('Copying %s \n', CellData_Master(i).name);
        [~,message,~] = copyfile([CELL_DATA_MASTER ,CellData_Master(i).name], CELL_DATA_FOLDER);
        if message
            disp(message)
        end
    end
end

disp('Done');