function projectFolder = makeTempFolderForExperiment(expName)
global ANALYSIS_FOLDER;
global CELL_DATA_FOLDER;
projectFolder = [ANALYSIS_FOLDER 'Projects' filesep expName '_temp'];
if ismac
    eval(['!rm -rf ' projectFolder]);
    eval(['!mkdir ' projectFolder]);
elseif ispc
    if exist(projectFolder, 'dir')
        rmdir(projectFolder) % won't remove if the directory already exists
    end
    mkdir(projectFolder)
end
cellNames = ls([CELL_DATA_FOLDER expName '*.mat']);
if ispc
    cellNames = cellstr(cellNames);
else
cellNames = strsplit(cellNames); %this will be different on windows - see doc ls
end
fid = fopen([projectFolder filesep 'cellNames.txt'], 'w');

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


