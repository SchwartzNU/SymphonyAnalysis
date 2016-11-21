classdef MovingBarConductanceSubtractionAnalysis < AnalysisTree
    %This is not like the other analysis classes. It needs to be run on an
    %already constructed tree with moving bar data for exc and inh.
    %The tree passed in will be the original analysis tree.
    %This class will rebuild that tree.
    %TreeBrowserGUI should be made to replace its analysisTree object with
    %the new one created by this class.
    properties
        %currently these properties are not used
        StartTime = 0;
        EndTime = 0;
        respType = 'peak'
    end
    
    methods
        function obj = MovingBarConductanceSubtractionAnalysis(treeObj, params)
            %treeObj is previous tree (cell tree, children are analyses)
            rootData = treeObj.get(1);
            
            rootData.name = [rootData.name ': MovingBarConductanceSubtractionAnalysis'];
            %rootData = mergeStruct(rootData, params);
            obj = obj.set(1, rootData);
            obj = obj.addTreeLevel(treeObj, 'MovingBarAnalysis', 'RstarIntensity');
        end
        
        function obj = doAnalysis(obj)
            global ANALYSIS_FOLDER;
            chInd = obj.getchildren(1);
            for i=1:length(chInd)
                curChild = obj.get(chInd(i));
                chInd_analysisLevel = obj.getchildren(chInd(i));
                %find exc and inh nodes
                excNodeInd = [];
                inhNodeInd = [];
                for j=1:length(chInd_analysisLevel)
                    curNode = obj.get(chInd_analysisLevel(j));
                    if strcmp(curNode.(curNode.ampModeParam), 'Whole cell')
                        cellName = curNode.cellName;
                        deviceName = curNode.deviceName;
                        if curNode.(curNode.holdSignalParam) < 0 %excitation
                            excNodeInd = chInd_analysisLevel(j);
                        else %inhibition
                            inhNodeInd = chInd_analysisLevel(j);
                        end
                    end
                end
                if ~isempty(excNodeInd) && ~isempty(inhNodeInd) %if both are found, do the subtraction, we assume the same sorting of child nodes
                    barAngle_chInd_exc = obj.getchildren(excNodeInd);
                    barAngle_chInd_inh = obj.getchildren(inhNodeInd);
                    L = length(barAngle_chInd_exc);
                    differenceVals = zeros(1,L);
                    excNode = obj.get(excNodeInd);
                    angles = excNode.barAngle;
                    load([ANALYSIS_FOLDER filesep 'cellData' filesep cellName]); %loads cellData
                    for j=1:L
                        curExcNode = obj.get(barAngle_chInd_exc(j));
                        curInhNode = obj.get(barAngle_chInd_inh(j));
                        [excData, ~] = cellData.getMeanData(curExcNode.epochID, deviceName);
                        inhData = cellData.getMeanData(curInhNode.epochID, deviceName);
                        gE = excData / -60;
                        gI = inhData / 60;
                        diffTrace = gE - gI;
                        %rectify
                        diffTrace(diffTrace<0) = 0;
                        differenceVals(j) = sum(diffTrace); %take integral
                    end
                    curChild.cellName = cellName;
                    curChild.class = 'MovingBarConductanceSubtractionAnalysis';
                    curChild.barAngle = angles;
                    curChild.differenceVals = differenceVals;
                    obj = obj.set(chInd(i), curChild);
                end
            end
            
            
        end
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            rootData = node.get(1);
            angles = [rootData.barAngle rootData.barAngle(1)];
            diffVals = [rootData.differenceVals rootData.differenceVals(1)];
            polar(angles.*pi/180, diffVals);
            %hold on;
        end
        
    end
end

