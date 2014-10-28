function [] = makeTempFolderForExperiment(expName)
global ANALYSIS_FOLDER;
eval(['!rm -rf ' ANALYSIS_FOLDER 'Projects' filesep 'tempProject']);
eval(['!mkdir ' ANALYSIS_FOLDER 'Projects' filesep 'tempProject']);
cellNames = ls([ANALYSIS_FOLDER 'cellData' filesep expName 'c*.mat']);
cellNames = strsplit(cellNames); %this will be different on windows - see doc ls
fid = fopen([ANALYSIS_FOLDER 'Projects' filesep 'tempProject' filesep 'cellNames.txt'], 'w');

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


