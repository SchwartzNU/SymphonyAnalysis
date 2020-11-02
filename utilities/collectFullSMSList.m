function allCells = collectFullSMSList()
D = dir;

allCells = [];

for i=1:length(D)
    if ~strcmp(D(i).name(1), '.')
        D(i).name
        curCells = importdata([D(i).name filesep 'cellNames.txt']);
        allCells = [allCells; curCells];
    end
end

fid = fopen('cellNames.txt', 'w');
for i=1:length(allCells)
    fprintf(fid, '%s\n', allCells{i});    
end
fclose(fid);