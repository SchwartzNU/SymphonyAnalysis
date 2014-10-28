function [] = makeTempFolderForExperiment(expName)
global ANALYSIS_FOLDER;
eval(['!rm -rf ' ANALYSIS_FOLDER 'Projects' filesep 'tempProject']);
eval(['!mkdir ' ANALYSIS_FOLDER 'Projects' filesep 'tempProject']);
cellNames = ls([ANALYSIS_FOLDER 'cellData' filesep expName 'c*.mat']);
cellNames = strsplit(cellNames); %this will be different on windows - see doc ls
fid = fopen([ANALYSIS_FOLDER 'Projects' filesep 'tempProject' filesep 'cellNames.txt'], 'w');
for i=1:length(cellNames)   %does not consider merged cells: this needs to be done by hand for now
    [~, basename, ~] = fileparts(cellNames{i});
    if ~isempty(basename)
        fprintf(fid, '%s\n', basename);
    end
end
fclose(fid);


