function correctAnglesForProject(projFolder)

global CELL_DATA_FOLDER
global ANALYSIS_FOLDER

if nargin == 0
    projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep]);
end


fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
if fid < 0
    error(['Error: cellNames.txt not found in ' projFolder]);
    return;
end
temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

files = {};
for i = 1:length(cellNames)
    cellNameParts = textscan(cellNames{i}, '%s', 'delimiter', ',');
    cellNameParts = cellNameParts{1}; %quirk of textscan
    files = [files; cellNameParts];
end

%% load cellData names

numFiles = length(files);

%% loop through cellData
% angles are relative to moving bar towards direction
for fi = numFiles:-1:1
    fprintf('processing cellData %d of %d: %s\n', fi, numFiles, files{fi})
    fname = fullfile(CELL_DATA_FOLDER, [files{fi}, '.mat']);
    load(fname)
    
    
    cellData = correctAngles(cellData, files{fi});
    if cellData == 1
        continue
    end

    %% Save cellData
    disp('saving cell data');
    save(fname, 'cellData');
    
end
