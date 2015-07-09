function [] = makeCombinedProject(year, months)
global ANALYSIS_FOLDER;
expDateFolder = uigetdir([ANALYSIS_FOLDER filesep 'Projects'], 'Select expDate projects folder');

expFolders = dir(expDateFolder);
L = length(expFolders);
expMatch = zeros(1,L);
cellNames = [];
for i=1:L
    curName = expFolders(i).name;
    %str2double(curName(5:6))
    if strcmp(curName(1), '.') || length(curName) < 7
        %do nothing, non exp folder
    elseif str2double(curName(5:6)) == year && any(months == str2double(curName(1:2)))
        expMatch(i) = 1;
        projFolder = [expDateFolder filesep curName filesep]
        %read in cellNames folder from project
        fid = fopen([projFolder 'cellNames.txt'], 'r');
        if fid < 0
            errordlg(['Error: cellNames.txt not found in ' projFolder]);
            return;
        end
        temp = textscan(fid, '%s', 'delimiter', '\n');
        cellNames = [cellNames; temp{1}];
        fclose(fid);
    end
end

disp([num2str(sum(expMatch)) ' experiments: ' num2str(length(cellNames)) ' cells']);

%make new project
dirName = [ANALYSIS_FOLDER filesep 'Projects' filesep '20' num2str(year) '_' num2str(months(1)) 'to' num2str(months(end))];
if exist(dirName) == 7
    rmdir(dirName);
end
mkdir(dirName);
fid = fopen([dirName filesep 'cellNames.txt'], 'w');
for j=1:length(cellNames)
    if ~isempty(cellNames{j})
        fprintf(fid, '%s\n', cellNames{j});
    end
end
fclose(fid);
