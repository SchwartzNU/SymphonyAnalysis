cellData_folder = [ANALYSIS_FOLDER 'cellData' filesep];

projFolder = uigetdir
% projFolder = '/Users/sam/analysis/Projects/WFDS_all';


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
    
    
    % set cell type
%     disp(cellData.cellType)
%     if strcmp(cellData.cellType, 'ON transient LSDS')
%         cellData.cellType = 'ON WFDS';
%         disp('renamed')
%         save(fname, 'cellData');
%     end

    cellData.tags('RecordedBy') = 'Sam';


%     cellData.location
%     
%     dataSetNames = cellData.savedDataSets.keys;
%     dgset_ca = strncmpi('DriftingGratings_ca', dataSetNames, 20);
%     if ~any(dgset_ca)
%         dgset_ca = strncmpi('DriftingGratings', dataSetNames, 20);
%     end
%     
%     cellData.savedDataSets('DriftingGratings_ca')
%     


    %% Save cellData
    save(fname, 'cellData');
    
end
