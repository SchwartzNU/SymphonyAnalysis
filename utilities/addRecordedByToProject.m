function addRecordedByToProject(projFolder, myname)

global ANALYSIS_FOLDER
cellData_folder = [ANALYSIS_FOLDER 'cellData' filesep];

fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
if fid < 0
    errordlg(['Error: cellNames.txt not found in ' projFolder]);
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
for fi = 1:numFiles
    fprintf('processing cellData %d of %d: %s\n', fi, numFiles, files{fi})
    fname = fullfile(cellData_folder, [files{fi}, '.mat']);
    load(fname)

    cellData.tags('RecordedBy') = myname;

    save(fname, 'cellData');
    
end
