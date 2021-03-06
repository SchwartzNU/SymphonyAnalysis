function projectFolder = makeTempFolderForExperiment(expName)
ANALYSIS_FOLDER = getenv('ANALYSIS_FOLDER');
CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
projectFolder = [ANALYSIS_FOLDER filesep 'Projects' filesep expName '_temp'];
if ismac
    eval(['!rm -rf ' projectFolder]);
    eval(['!mkdir ' projectFolder]);
elseif ispc
    if exist(projectFolder, 'dir')
        delete([projectFolder, filesep, '*']);
    else
        mkdir(projectFolder)
    end
end
cellNames = ls([CELL_DATA_FOLDER filesep expName '*.mat']);
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


