function [locationList] = getLocationFromProject( projectName )
global CELL_DATA_FOLDER
global ANALYSIS_FOLDER

%% Open file
folder_name = uigetdir([ANALYSIS_FOLDER 'Projects/'],'Choose project folder');
obj.projFolder = [folder_name filesep];

fid = fopen([obj.projFolder 'cellNames.txt'], 'r');
if fid < 0
    errordlg(['Error: cellNames.txt not found in ' obj.projFolder]);
    close(obj.fid);
    return;
end

temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

%% Iterate through CellNames to get all locations

locationList = {};

for iter = 1:length(cellNames)
    currData = load( [CELL_DATA_FOLDER cellNames{iter,1} '.mat'] );
    if(size(currData.cellData.location) > 0)
        locationList(iter, :) = {currData.cellData.location(1), currData.cellData.location(2), currData.cellData.location(3), currData.cellData.cellType};
    end

end

locationList = cell2table(locationList);

%%
for iter = 1:width(SMS_locs_table)
    for jter = 1:height(SMS_locs_table)
        if iscell(SMS_locs_table(jter,iter))
            SMS_locs_table(jter,iter) = cell2mat(SMS_locs_table(jter,iter));
        else
        end
    end
end

