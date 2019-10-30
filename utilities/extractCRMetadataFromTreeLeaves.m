function [ dataArray ] = extractCRMetadataFromTreeLeaves(T)
global CELL_DATA_FOLDER
%T is analysis tree

leafNodes = T.findleaves;
nLeaves = length(leafNodes);

dataArray = {};
dataRow = 1;

lastNodeID = 0;

for i=1:nLeaves    
        curNodeID = T.Parent(leafNodes(i));
        curNode = T.get(curNodeID);
        parent = T.get(T.Parent(T.Parent(T.Parent((leafNodes(i))))));
        cellType = parent.name;
        if isnan(curNode.spotSize)
            spotSize = curNode.spotDiameter;
        else
            spotSize = curNode.spotSize;
        end
        
        if curNodeID ~= lastNodeID
            [cellName, rest] = strtok(curNode.name, ':');
            datasetName = strtok(deblank(rest), ':');
            datasetName = datasetName(2:end);
            dataArray(dataRow,:) = { cellType, cellName,...
                spotSize, curNode.RstarMean,...
                curNode.spikeCount_stimInterval_baselineSubtracted.mean_c(1),...
                curNode.spikeCount_stimInterval_baselineSubtracted.mean_c(length(curNode.spikeCount_stimInterval_baselineSubtracted.mean_c))...
                curNode.ONSETspikes_200ms_grandBaselineSubtracted.mean_c(1),...
                curNode.ONSETspikes_200ms_grandBaselineSubtracted.mean_c(length(curNode.ONSETspikes_200ms_grandBaselineSubtracted.mean_c)),...
                };
           
            dataRow = dataRow+1;
        end
        lastNodeID = curNodeID;
end

dataArray = cell2table(dataArray);

dataArray.Properties.VariableNames{1} = 'cellType';
dataArray.Properties.VariableNames{2} = 'cellName';
dataArray.Properties.VariableNames{3} = 'spotSize';
dataArray.Properties.VariableNames{4} = 'RstarMean';
dataArray.Properties.VariableNames{5} = 'full_negContrast';
dataArray.Properties.VariableNames{6} = 'full_posContrast';
dataArray.Properties.VariableNames{7} = 'init_negContrast';
dataArray.Properties.VariableNames{8} = 'init_posContrast';


end
