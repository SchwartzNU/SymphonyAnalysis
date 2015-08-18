function [] = exportPlotTypeFromTree(T, fname, plotterName, analysisClass)
global IGOR_H5_folder;
nodes = getTreeLevel_new(T, 'class', analysisClass);
L = length(nodes);
h = figure;
ax = gca;
for i=1:L    
    curNode = nodes(i);
    cellName = T.getCellName(curNode);
    cellData = loadAndSyncCellData(cellName);
    curNode = T.subtree(curNode);
    curNodeData = curNode.get(1);
    nodeName = curNodeData.name;  
    
    temp = textscan(nodeName, '%s', 'Delimiter', ':');
    temp = temp{1};
    datasetName = temp{2};
    try
        %disp([analysisClass '.' plotterName '(curNode, cellData);']);
        eval([analysisClass '.' plotterName '(curNode, cellData);']);        
        makeAxisStruct(ax, IGOR_H5_folder, fname, [cellName '_' datasetName])
    catch
        disp(['plot error: skipping ' cellName '_' datasetName]);
    end
    
end

