function [cellNames, dataSetNames, paramForCells] = allParamsAcrossCells(analysisTree, paramList)
%Will extract all parameters from analysis for any of analysis class.
%Doesn't extract celltypes, give it a tree of a single cell type.
%CHANGE 3/23/15: will return analysis data-set name

numParam = length(paramList);


%Find all analyses of analysisClass in tree
analysisClass = [];
analisysClassInd = [];
numNodes = length(analysisTree.Node);
for nodeInd = 1:numNodes
    if isfield(analysisTree.Node{nodeInd},'class')
%         if strcmp(analysisTree.Node{nodeInd}.class,analysisClass)
%         %ASSUMING ALL BELONG TO A SINGLE ANALYSIS CLASS
            if isempty(analysisClass)
                analysisClass = analysisTree.Node{nodeInd}.class;
            end;
            %if strcmp(analysisTree.Node{nodeInd}.ampMode, 'Cell attached')
                %can put more filtering conditions on data sets here
                analisysClassInd = [analisysClassInd, nodeInd];
            %end;
%         end;
    end;
end;    



%initialize variables
numAnalysisClassNodes = length(analisysClassInd);   
cellNames = cell(numAnalysisClassNodes, 1);
dataSetNames = cell(numAnalysisClassNodes, 1);
paramMatrix = cell(numParam, numAnalysisClassNodes);


%extract parameters
for nodeInd=1:numAnalysisClassNodes
    curAnalysisNode = analysisTree.get(analisysClassInd(nodeInd));
    cellNames{nodeInd} = curAnalysisNode.cellName;
    dataSetNames{nodeInd} = curAnalysisNode.name;
    leafInd = analysisTree.getchildren(analisysClassInd(nodeInd));   %Where responses are stored.
    %numLeafs = length(leafInd);   %ASSUMING =1
    curLeaf = analysisTree.get(leafInd);
    switch analysisClass
        case {'MovingBarAnalysis', 'BarsMultiAngleAnalysis'}
            XparamValues = curAnalysisNode.barAngle;
        case 'SpotsMultiSizeAnalysis'
            XparamValues = curAnalysisNode.spotSize;
    end;
    

    for paramInd = 1:numParam
        paramIsStruct = 0;
        YparamName = paramList{paramInd};
        if ~isempty(strfind(YparamName,'.'))
            YparamStructName = YparamName(1:strfind(YparamName,'.')-1);
            paramIsStruct = 1;
        else
            YparamStructName = YparamName;
        end;
        if isfield(curAnalysisNode, YparamStructName)
            eval(['YparamValues = curAnalysisNode.',YparamName,';']);
            if paramIsStruct && isfield(curAnalysisNode.(YparamStructName), 'SEM')
                if ~isempty(strfind(YparamName,'_c')) %assuming using mean_c or median_c
                    YparamSEM = curAnalysisNode.(YparamStructName).SEM_c;
                else
                    YparamSEM = curAnalysisNode.(YparamStructName).SEM; %suuming using mean or median
                end;
            else
                YparamSEM = zeros(1,length(YparamValues));
            end;
            if length(YparamValues) == 1 %scalar (meta-parameter?)
                paramMatrix{paramInd, nodeInd} = YparamValues;
            elseif length(YparamValues) > 1 %vector
                paramMatrix{paramInd, nodeInd} = [XparamValues; YparamValues; YparamSEM];
            end;
        elseif isfield(curLeaf, YparamStructName) %Look in leaf if not found in parent.
            eval(['YparamValues = curLeaf.',YparamName,';']);
            paramMatrix{paramInd, nodeInd} = YparamValues;
        end;
        
    end;

end;

paramForCells = paramMatrix;


end