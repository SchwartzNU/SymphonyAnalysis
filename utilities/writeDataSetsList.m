function [] = writeDataSetsList(fname, cellDataDir)
if nargin < 2
    cellDataDir = '~/analysis/cellData';
end
if nargin < 1
   fname = '~/analysis/dataSets.txt';   
end

curDir = pwd;
cd(cellDataDir);
D = dir;
fid = fopen(fname, 'w+');
allDataSets = {};
z=1;
for i=1:length(D)
   if strfind(D(i).name, '.mat')       
       load(D(i).name);
       dataSetKeys = cellData.savedDataSets.keys;       
       allDataSets{1,z} = D(i).name;       
       for j=1:length(dataSetKeys);
           allDataSets{j+1,z} = dataSetKeys{j};
       end
       z=z+1;
   end
end

[r,c] = size(allDataSets);
for i=1:r
    for j=1:c
        fprintf(fid, '%s\t', allDataSets{i,j});
    end
    fprintf(fid, '\r');
end
fclose(fid);

cd(curDir);