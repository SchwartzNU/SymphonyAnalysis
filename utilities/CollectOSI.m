function [OSICells, OSI, OSAng] = CollectOSI()
global ANALYSIS_FOLDER

if nargin == 0
    [fname, pathname] = uigetfile([ANALYSIS_FOLDER filesep 'analysisTrees' filesep '*.mat'], 'Load analysisTree');
end

load(fullfile(pathname, fname)); %loads analysisTree
global analysisTree
T = analysisTree;
analysisClass = 'DriftingGratingsAnalysis';
%analysisClass = 'BarsMultiAngleAnalysis';

nodes = getTreeLevel_new(T, 'class', analysisClass);
L = length(nodes);

Count = 1;
OSICells = {'cell array of character vectors'};

for i=1:L
    curNode = nodes(i);
    cellName = {T.getCellName(curNode)};
    
    if any(contains(OSICells, cellName));
        continue
    else
        curNode = T.subtree(curNode);
        %curNodeData = curNode.get(1);
        curNodeData = curNode.get(4);

        OSI(Count) = curNodeData.F1amplitude_OSI;
        OSAng(Count) = curNodeData.F1amplitude_OSang;
        OSICells(Count) = cellName;

        Count = Count + 1;
    end
end
