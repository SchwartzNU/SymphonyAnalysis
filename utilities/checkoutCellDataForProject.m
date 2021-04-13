function [] = checkoutCellDataForProject(cellNames)
ANALYSIS_FOLDER = getenv('ANALYSIS_FOLDER');
CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
CELL_DATA_MASTER = [getenv('SERVER_ROOT') filesep 'CellDataMaster'];

if nargin < 1
    projFolder = uigetdir([ANALYSIS_FOLDER filesep 'Projects' filesep], 'Choose project folder');

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
        cellData_fname = [cellDataNames{j} '.mat'];
        if exist([CELL_DATA_FOLDER filesep cellData_fname], 'file') %already have the file
            %do nothing
        else
            if exist([CELL_DATA_MASTER filesep cellData_fname], 'file')
                disp(['Copying ' cellData_fname]);
                if ismac
                    st = ['!cp -p ' [CELL_DATA_MASTER filesep cellData_fname] ' ' [CELL_DATA_FOLDER filesep]];
                    eval(st);
                elseif ispc
                    copyfile([CELL_DATA_MASTER filesep cellData_fname], [CELL_DATA_FOLDER filesep]);
                end
            else
                disp([CELL_DATA_MASTER filesep cellData_fname ' not found']);
            end
        end
    end
end
disp('Done');