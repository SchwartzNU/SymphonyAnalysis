function [] = checkoutRawDataForProject(cellNames)
global ANALYSIS_FOLDER;
global RAW_DATA_FOLDER;
global RAW_DATA_MASTER;

if nargin < 1
    projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep], 'Choose project folder');

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
        rawData_fname = [cellDataNames{j} '.h5'];
        
        n = strsplit(cellDataNames{j}, 'c');
        rawData_fname_symphony2 = [n{1} '.h5'];
        
        if exist([RAW_DATA_FOLDER rawData_fname], 'file') %already have the file
            
        elseif exist([RAW_DATA_FOLDER rawData_fname_symphony2], 'file')
%             fprintf('found sym2 raw data: %s\n', cellDataNames{j})
        else
            if exist([RAW_DATA_MASTER rawData_fname], 'file')
                disp(['Copying ' rawData_fname]);
                if ismac
                    eval(['!cp -r ' [RAW_DATA_MASTER rawData_fname] ' ' RAW_DATA_FOLDER]);
                elseif ispc
                    copyfile([RAW_DATA_MASTER rawData_fname], RAW_DATA_FOLDER);
                end
            elseif exist([RAW_DATA_MASTER rawData_fname_symphony2], 'file')
                disp(['Copying ' rawData_fname_symphony2]);
                if ismac
                    eval(['!cp -r ' [RAW_DATA_MASTER rawData_fname_symphony2] ' ' RAW_DATA_FOLDER]);
                elseif ispc
                    copyfile([RAW_DATA_MASTER rawData_fname_symphony2], RAW_DATA_FOLDER);
                end
            else
                disp(['in ' RAW_DATA_MASTER ', ' rawData_fname ' or ' rawData_fname_symphony2 ' not found']);
            end
        end
    end
end
disp('Done');