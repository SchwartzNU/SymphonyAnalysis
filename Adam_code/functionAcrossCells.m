function [cellNames, paramForCells] = functionAcrossCells(analysisTree, analysisClass, YparamName)
%Scans analysisTree of multiple cells and collects parameter values.
%Adam 12/22/14 based on paramAcrossCells, generalized to multi-leaf analyses.


analisysClassInd = [];


%Find all analyses of analysisClass in tree
numNodes = length(analysisTree.Node);
for nodeInd = 1:numNodes
    if isfield(analysisTree.Node{nodeInd},'class')
        if strcmp(analysisTree.Node{nodeInd}.class,analysisClass)
            analisysClassInd = [analisysClassInd, nodeInd];
        end;
    end;
end;    

numAnalysisClassNodes = length(analisysClassInd); 
paramValues = cell(numAnalysisClassNodes, 1);
cellNames = cell(numAnalysisClassNodes, 1);

for i=1:numAnalysisClassNodes
    curAnalysisNode = analysisTree.get(analisysClassInd(i));
    if strcmp(curAnalysisNode.ampMode, 'Cell attached') %%&& strcmp(curNode.class, analysisClass)
        cellNames{i} = curAnalysisNode.cellName;
        leafInd = analysisTree.getchildren(analisysClassInd(i));   %Where responses are stored. 
        numLeafs = length(leafInd);
        XparamValuesForCell = zeros(1, numLeafs);
        YparamValuesForCell = zeros(1, numLeafs);
        for j = 1:numLeafs
            curLeaf = analysisTree.get(leafInd(j));
            standardAnalysisCondition = all([1 1]); %temp;
            if standardAnalysisCondition
                  XparamValuesForCell(j) = curLeaf.splitValue;
                  eval(['YparamValuesForCell(j) = curLeaf.',YparamName,';']);
            end
            %actually could use the "percolated-up" vectors...
        end;
        paramValues{i} = [XparamValuesForCell; YparamValuesForCell];
    end
end

paramForCells = paramValues;


end

