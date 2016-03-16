function [newCellTypeList, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList)


node1Name = analysisTree.Node{1}.name;
analysisClass = node1Name(length('Collected analysis tree: ')+1:end);
numParams = length(paramList);
numTypes = length(cellTypeList);


% % next lines remove cell types from the list that were not found in the tree
cellTypesFound = cell(0);
cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:numTypes
    for nodeInd = 1:length(cellTypeNodes)
        curCellType = analysisTree.Node{cellTypeNodes(nodeInd)}.name;
        if ~isempty( strfind(curCellType, cellTypeList{cellTypeInd}))
            cellTypesFound = [cellTypesFound; cellTypeList{cellTypeInd}];
        end;
    end;
end;
cellTypesFound = unique(cellTypesFound);
newCellTypeList = cellTypesFound;
%numTypes = length(cellTypeList);
% %

%Find one analysis of analysisClass in tree

numNodes = length(analysisTree.Node);
for nodeInd = 1:numNodes
    if isfield(analysisTree.Node{nodeInd},'class')
        if strcmp(analysisTree.Node{nodeInd}.class,analysisClass) && strcmp(analysisTree.Node{nodeInd}.ampMode,'Cell attached')
            OneAalisysClassInd = nodeInd;
            break;
        end;
    end;
end;    

%Sample tree and narrow down parameter list
sampleAnalysis =  analysisTree.get(OneAalisysClassInd);
sampleLeafInd = analysisTree.getchildren(OneAalisysClassInd);
sampleLeaf = analysisTree.get(sampleLeafInd(1));
%paramFoundParent = cell(0);
%paramFoundChild = cell(0);
paramFound = cell(0);
for paramInd = 1:numParams
    paramName = paramList{paramInd};
    if ~isempty(strfind(paramName,'.'))     %structured parameter, e.g. 'ONSETspikes.mean'
        paramStructName = paramName(1:strfind(paramName,'.')-1);
        paramTypeName = paramName(strfind(paramName,'.')+1:end);
        if isfield(sampleAnalysis,paramStructName)
            %paramFoundParent = [paramFoundParent; paramList{paramInd}];
            sampleVal = [sampleAnalysis.(paramStructName).(paramTypeName)];
            if length(sampleVal) == 1 %ignore vector params here for now
                paramFound = [paramFound; paramList{paramInd}];
            end;
        elseif isfield(sampleLeaf,paramStructName)
            %paramFoundChild = [paramFoundChild; paramList{paramInd}];
            paramFound = [paramFound; paramList{paramInd}];
        end;
        
    else    %simple parameter, e.g. 'Xmax_ONSETspikes'
        
        if isfield(sampleAnalysis,paramName)
            %paramFoundParent = [paramFoundParent; paramList{paramInd}];
            sampleVal = [sampleAnalysis.(paramName)];
            if length(sampleVal) == 1 %ignore vector params here for now
                paramFound = [paramFound; paramList{paramInd}];
            end;
        elseif isfield(sampleLeaf,paramName)
            %paramFoundChild = [paramFoundChild; paramList{paramInd}];
            paramFound = [paramFound; paramList{paramInd}];
        end;
        
    end;
end;
    
% paramListChild = unique(paramFoundChild);
% paramListParent = unique(paramFoundParent);
paramList = unique(paramFound);
newCellTypeList = unique(cellTypesFound);
