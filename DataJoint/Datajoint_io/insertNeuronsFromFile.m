function [] = insertNeuronsFromFile(fname)
global ANALYSIS_FOLDER

if nargin == 0 %no filename provided
    [fname, fpath] = uigetfile([ANALYSIS_FOLDER filesep 'Projects' filesep '*.txt'], 'Choose cellNames.txt file');
end

fid = fopen([fpath fname], 'r');
temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

Ncells = length(cellNames);
for i=1:Ncells
   curName = strtrim(cellNames{i});
   insert(sl.Neuron, {curName}, 'IGNORE'); %ignores duplicate entries
end






