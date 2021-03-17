function [] = checkoutCellDataForProject(cellNames)
ANALYSIS_FOLDER = getenv('ANALYSIS_FOLDER');
% CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
% CELL_DATA_MASTER = getenv('CELL_DATA_MASTER');
SERVER_ROOT = getenv('SERVER_ROOT');
RAW_IMAGE_FOLDER = getenv('RAW_IMAGE_FOLDER');

if nargin < 1
    projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep], 'Choose project folder');
    
    disp('Choose server image folder')
    copyFromFolder = uigetdir(SERVER_ROOT, 'Choose server image folder');
    
    disp('Choose where to place images')
    copyToFolder = uigetdir(RAW_IMAGE_FOLDER, 'Choose where to place images');
    
    fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
    if fid < 0
        errordlg(['Error: cellNames.txt not found in ' projFolder]);
        return;
    end
    temp = textscan(fid, '%s', 'delimiter', '\n');
    cellNames = temp{1};
    fclose(fid);
end

fprintf('Checking for %g files\n', length(cellNames));

for i=1:length(cellNames)
    cellDataNames = cellNameToCellDataNames(cellNames{i});
    for j=1:length(cellDataNames)
        cellData_fname = [cellDataNames{j}];
        if exist([copyToFolder filesep cellData_fname], 'file') %already have the  image
            %do nothing
        else
            if exist([copyFromFolder filesep cellData_fname], 'file')
                disp(['Copying ' cellData_fname]);
                copyfile([copyFromFolder filesep cellData_fname],[copyToFolder filesep cellData_fname])
            else
                disp([cellData_fname ' not found']);
            end
        end
    end
end
disp('Done');