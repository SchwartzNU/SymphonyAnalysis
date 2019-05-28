function [] = extractPSTHFromTreeLeaves(T, fname)
global CELL_DATA_FOLDER
%T is analysis tree

leafNodes = T.findleaves;
nLeaves = length(leafNodes);

for i=1:nLeaves    
        curNode = T.get(T.Parent(leafNodes(i)));
        [cellName, rest] = strtok(curNode.name, ':');
        datasetName = strtok(deblank(rest), ':');
        datasetName = datasetName(2:end);
        
        load([CELL_DATA_FOLDER cellName]);
        epochInd = cellData.savedDataSets(datasetName);
        [psth_y, psth_x] = cellData.getPSTH(epochInd);
        s = struct;
        s.psth_x = psth_x;
        s.psth_y = psth_y;
        exportStructToHDF5(s, fname, [cellName '_' datasetName]);
end