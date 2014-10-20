function [] = checkoutRawDataForProject
global ANALYSIS_FOLDER;
global RAW_DATA_FOLDER;
cellData_folder = uigetdir(ANALYSIS_FOLDER, 'Choose cellData folder');
rawData_folder = uigetdir([],'Choose raw data folder from which to copy data');
d = dir(cellData_folder);
for i=1:length(d)
   if strfind(d(i).name, '.mat');
       basename = strtok(d(i).name, '.mat');
       rawData_fname = [basename '.h5'];
       if exist([rawData_folder filesep rawData_fname], 'file')
           disp(['Copying ' rawData_fname]);
           eval(['!cp -r ' [rawData_folder filesep rawData_fname] ' ' RAW_DATA_FOLDER]);
       else
          disp([rawData_folder filesep rawData_fname ' not found']);
       end
   end       
end