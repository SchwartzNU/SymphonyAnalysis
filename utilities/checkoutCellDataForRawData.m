function [] = checkoutCellDataForRawData()
global CELL_DATA_FOLDER;
global CELL_DATA_MASTER;
global RAW_DATA_FOLDER;

if ~exist(CELL_DATA_MASTER,'dir')
    error('Could not connect to CellDataMaster')
end

DataName = uigetfile([RAW_DATA_FOLDER,'*.h5'], 'Choose raw data file');
DataName = erase(DataName,'.h5');

disp('Looking for matching cellData in CellDataMaster')
CellData_Master = dir([CELL_DATA_MASTER,DataName,'*']);

CellData_Local = dir([CELL_DATA_FOLDER,DataName,'*']);
CellData_LocalNames = struct2cell(CellData_Local);
CellData_LocalNames = CellData_LocalNames(1,:);

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