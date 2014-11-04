function [] = resetAllCellDataPaths()
global ANALYSIS_FOLDER;
cellData_folder = uigetdir(ANALYSIS_FOLDER, 'Choose cellData folder for files to update');
cellData_original_folder = uigetdir(ANALYSIS_FOLDER, 'Choose folder for saved cellData originals');
d = dir(cellData_folder);
for i=1:length(d)
   if strfind(d(i).name, '.mat');
       disp(['Processing ' d(i).name]);
       load([cellData_folder filesep d(i).name]); %load cellData
       cellData.resetSavedFileName(cellData_original_folder);
   end       
end



