function [cellNames, paramForCells] = paramAcrossCells(analysisTree, paramName)
%Scans analysisTree of multiple cells and collects parameter values.
%Adam 11/13/14 based on 10/23/14


LightStepInd = [];


%Find all LightStep analyses in tree
numNodes = length(analysisTree.Node);
for nodeInd = 1:numNodes
    if isfield(analysisTree.Node{nodeInd},'class')
        if strcmp(analysisTree.Node{nodeInd}.class,'LightStepAnalysisTEMP')
            LightStepInd = [LightStepInd, nodeInd];
        end;
    end;
end;    

numLightStepNodes = length(LightStepInd);
paramValues = [];
cellNames = [];

for i=1:numLightStepNodes
    
    curNode = analysisTree.get(LightStepInd(i));
    if strcmp(curNode.ampMode, 'Cell attached') && strcmp(curNode.class, 'LightStepAnalysisTEMP')
        leafInd = analysisTree.getchildren(LightStepInd(i));   %Where responses are stored. "splitparam == RstarMean" has only one value.
        curLeaf = analysisTree.get(leafInd);
        standardLightStepCondition = all([ 1 1]); %temp;
        if standardLightStepCondition
            cellNames{i} = curNode.cellName;
            eval(['paramValues = [paramValues; curLeaf.',paramName,'];']);
        end
    end
end

paramForCells = paramValues;


end

