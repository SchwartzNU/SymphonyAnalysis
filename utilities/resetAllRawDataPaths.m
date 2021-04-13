function [] = resetAllRawDataPaths()
ANALYSIS_FOLDER = [getenv('ANALYSIS_FOLDER') filesep];
RAW_DATA_FOLDER = [getenv('RAW_DATA_FOLDER') filesep];
cellData_folder = uigetdir(ANALYSIS_FOLDER, 'Choose cellData folder');
rawData_folder = uigetdir(RAW_DATA_FOLDER, 'Choose raw data folder');
d = dir(cellData_folder);
for i=1:length(d)
   if strfind(d(i).name, '.mat');
       disp(['Processing ' d(i).name]);
       load([cellData_folder filesep d(i).name]); %load cellData
       cellData.resetRawDataFolder(rawData_folder);
   end       
end


