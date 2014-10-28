function [] = addCellsToProject()
global ANALYSIS_FOLDER;
projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep], 'Choose project folder');
cellData_folder = uigetdir([ANALYSIS_FOLDER], 'Choose folder with cellData files');

cellNames = ls([cellData_folder filesep '*.mat']);
cellNames = strsplit(cellNames); %this will be different on windows - see doc ls
cellNames = sort(cellNames);
if ~exist([projFolder filesep 'cellNames.txt'], 'file');
    fid = fopen([projFolder filesep 'cellNames.txt'], 'w');
else
    fid = fopen([projFolder filesep 'cellNames.txt'], 'a');
end

cellBaseNames = cell(length(cellNames), 1);
for i=1:length(cellNames)      
    [~, basename, ~] = fileparts(cellNames{i});
    cellBaseNames{i} = basename;    
end

cellBaseNames = mergeCellNames(cellBaseNames);
for i=1:length(cellBaseNames)
    if ~isempty(cellBaseNames{i})
        fprintf(fid, '%s\n', cellBaseNames{i});
    end
end
fclose(fid);
