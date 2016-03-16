function [] = exportPlotTypeFromTree(T, fname, plotterName, analysisClass)
global IGOR_H5_folder;
IGOR_H5_folder = './';
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
    
    
    if ~isempty(strfind(nodeName,analysisClass))
        temp = textscan(nodeName, '%s', 'Delimiter', ':');
        temp = temp{1};
        datasetName = temp{2};
        
        if strfind(datasetName,'Annulus') %hack Adam 11/3/15
            datasetName = datasetName(length('Annulus')+1:end);
            datasetName = ['an',datasetName];
        elseif strfind(datasetName,'TextureMatrix')
            datasetName = datasetName(length('TextureMatrix')+1:end);
            datasetName = ['tm',datasetName];
        elseif strfind(datasetName,'ContrastResp')
            datasetName = datasetName(length('ContrastResp')+1:end);
            datasetName = ['cr',datasetName];
        elseif strfind(datasetName,'SpotsMultiSize')
            datasetName = datasetName(length('SpotsMultiSize')+1:end);
            datasetName = ['sms',datasetName];
        end;
        
        try
            disp([analysisClass '.' plotterName '(curNode, cellData);']);
            %pause;
            eval([analysisClass '.' plotterName '(curNode, cellData);']);
            makeAxisStruct(ax, IGOR_H5_folder, fname, [cellName '_' datasetName])
        catch
            disp(['plot error: skipping ' cellName '_' datasetName]);
        end
    end
    
end

