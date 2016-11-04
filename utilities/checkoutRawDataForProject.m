function [] = checkoutRawDataForProject
global ANALYSIS_FOLDER;
global RAW_DATA_FOLDER;
projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep], 'Choose project folder');
rawData_folder = uigetdir([],'Choose raw data folder from which to copy data');

fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
if fid < 0
    errordlg(['Error: cellNames.txt not found in ' projFolder]);
    return;
end
temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

for i=1:length(cellNames)
    cellDataNames = cellNameToCellDataNames(cellNames{i});
    for j=1:length(cellDataNames)
        rawData_fname = [cellDataNames{j} '.h5'];
        
        n = split(cellDataNames{j}, 'c');
        rawData_fname_symphony2 = [n{1} '.h5'];
        
        if exist([RAW_DATA_FOLDER rawData_fname], 'file') %already have the file
            
        elseif exist([RAW_DATA_FOLDER rawData_fname_symphony2], 'file')
%             fprintf('found sym2 raw data: %s\n', cellDataNames{j})
        else
            if exist([rawData_folder filesep rawData_fname], 'file')
                disp(['Copying ' rawData_fname]);
                eval(['!cp -r ' [rawData_folder filesep rawData_fname] ' ' RAW_DATA_FOLDER]);
                
            elseif exist([RAW_DATA_FOLDER rawData_fname_symphony2], 'file')
                disp(['Copying ' rawData_fname_symphony2]);
                eval(['!cp -r ' [rawData_folder filesep rawData_fname_symphony2] ' ' RAW_DATA_FOLDER]);
            else
                disp([rawData_folder filesep rawData_fname ' not found']);
            end
        end
    end
end