function [OSICells, OSI, OSAng] = CollectOSI(analysisClass)
global ANALYSIS_FOLDER

[fname, pathname] = uigetfile([ANALYSIS_FOLDER filesep 'analysisTrees' filesep '*.mat'], 'Load analysisTree');

load(fullfile(pathname, fname)); %loads analysisTree
T = analysisTree;
%analysisClass = 'DriftingGratingsAnalysis';
analysisClass = 'BarsMultiAngleAnalysis';

nodes = getTreeLevel_new(T, 'class', analysisClass);
L = length(nodes);

Count = 1;
OSICells = {'cell array of character vectors'};

for i=1:L
    curNode = nodes(i);
    cellName = {T.getCellName(curNode)};
    
    if any(contains(OSICells, cellName))
        display('already got that one')
    else
    	curNode = T.subtree(curNode);
    	OSICells(Count) = cellName;
        try
    	
            switch analysisClass
                    case 'DriftingGratingsAnalysis'
                        curNodeData = curNode.get(4);
                        OSI(Count) = curNodeData.F1amplitude_OSI;
                        OSAng(Count) = curNodeData.F1amplitude_OSang;
                    case 'BarsMultiAngleAnalysis'
                        curNodeData = curNode.get(1);
                        OSI(Count) = curNodeData.spikeCount_stimInterval_baselineSubtracted_OSI
                        OSAng(Count) = curNodeData.spikeCount_stimInterval_baselineSubtracted_OSang
                    otherwise
                        display('We do not recognize this analysisClass')
            end
        catch
            display(['there was an error with', cellName])
        end
        Count = Count + 1;
    end
        
end
end
