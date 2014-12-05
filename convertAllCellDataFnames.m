function [] = convertAllCellDataFnames()
global ANALYSIS_FOLDER;
cellData_folder = uigetdir(ANALYSIS_FOLDER, 'Choose cellData folder');
d = dir(cellData_folder);
for i=1:length(d)
   if strfind(d(i).name, '.mat');
       curName = strtok(d(i).name, '.mat');
       disp(['Processing ' curName]);
       load([cellData_folder filesep d(i).name]); %load cellData       
       cellData.savedFileName = curName;
       %save([cellData_folder filesep curName], 'cellData');
       save([ANALYSIS_FOLDER 'cellData' filesep curName], 'cellData');
   end       
end
