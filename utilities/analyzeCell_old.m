function analyzeCell(cellName, overwrite, doPlots)
global ANALYSIS_FOLDER

if nargin < 3
    doPlots = true;
end
if nargin < 2
    overwrite = false;
end

    
fid = fopen([ANALYSIS_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

load([ANALYSIS_FOLDER 'cellData/' cellName]);
dataSetKeys = cellData.savedDataSets.keys;
cellAnalysisTree = AnalysisTree;
nodeData.name = ['Full cell analysis tree: ' cellName];
cellAnalysisTree = cellAnalysisTree.set(1, nodeData);

Nanalyses = length(analysisTable{1});

%check for 2 amps
if cellData.epochs(1).attributes.isKey('amp2Mode')
    twoAmps = true;
    cellAnalysisTree_Ch2 = AnalysisTree;
    nodeData.name = ['Full cell analysis tree: ' cellName];
    cellAnalysisTree_Ch2 = cellAnalysisTree_Ch2.set(1, nodeData);
else
    twoAmps = false;
end

T = [];
T2 = [];
if ~overwrite
    disp('loading analyses');
    %try to load existing analysis trees
    if exist([ANALYSIS_FOLDER 'analysisTrees/' cellName '.mat'], 'file')
        load([ANALYSIS_FOLDER 'analysisTrees/' cellName]);
        T = cellAnalysisTree;
    end
    if twoAmps
        if exist([ANALYSIS_FOLDER 'analysisTrees/' cellName '-Ch2.mat'], 'file')
            cellNamePart = strtok(cellName, '.mat');
            load([ANALYSIS_FOLDER 'analysisTrees/' cellNamePart '-Ch2.mat']);
            T2 = cellAnalysisTree_Ch2;
        end
    end
end

%run analyses
if isempty(T) || (twoAmps && isempty(T2))
    disp('running analyses');
    for i=1:length(dataSetKeys);
        T = [];
        for j=1:Nanalyses
            if strfind(dataSetKeys{i}, analysisTable{1}{j}) %only 1 should match
                curAnalysisClass = analysisTable{2}{j};
                if twoAmps
                    params.deviceName = 'Amplifier_Ch1';
                    eval(['T = ' curAnalysisClass '(cellData,' '''' dataSetKeys{i} '''' ', params);']);
                    T = T.doAnalysis(cellData);
                    params.deviceName = 'Amplifier_Ch2';
                    eval(['T2 = ' curAnalysisClass '(cellData,' '''' dataSetKeys{i} '''' ', params);']);
                    T2 = T2.doAnalysis(cellData);
                else
                    eval(['T = ' curAnalysisClass '(cellData,' '''' dataSetKeys{i} '''' ');']);
                    T = T.doAnalysis(cellData);
                end
                
            end
        end
        if ~isempty(T)
            cellAnalysisTree = cellAnalysisTree.graft(1, T);
            if twoAmps
                cellAnalysisTree_Ch2 = cellAnalysisTree_Ch2.graft(1, T2);
                cellNamePart = strtok(cellName, '.mat');
                save([ANALYSIS_FOLDER 'analysisTrees/' cellNamePart '-Ch2.mat'], 'cellAnalysisTree_Ch2');
            end
            save([ANALYSIS_FOLDER 'analysisTrees/' cellName], 'cellAnalysisTree');
            
        end
    end
end

%plotting
if doPlots
    plotInd = 1;
    chInd = cellAnalysisTree.getchildren(1);
    for i=1:length(chInd)
        curNode = cellAnalysisTree.subtree(chInd(i));
        curNodeData = curNode.get(1);
        curName = curNodeData.name;
        [~, str] = strtok(curName, ':');
        [~, str] = strtok(str, ':');
        [str, ~] = strtok(str, ':');
        curAnalysisClass = strtrim(str);
        
        allMethods = methods(curAnalysisClass);
        plotMethods = allMethods(strmatch('plot', allMethods));
        plotMethods = plotMethods(~strcmp(plotMethods, 'plot'));
        
        for p=1:length(plotMethods)
            figHandles(plotInd) = figure(plotInd);
            eval([curAnalysisClass '.' plotMethods{p} '(curNode, cellData)']);
            set(figHandles(plotInd), 'Name', [dataSetKeys{i} ': ' curAnalysisClass ': ' plotMethods{p}]);
            plotInd = plotInd + 1;
%             if twoAmps
%                 figHandles(plotInd) = figure(plotInd);
%                 eval(['T2.' plotMethods{p} '(curNode, cellData)']);
%                 set(figHandles(plotInd), 'Name',  ['Ch2: ' dataSetKeys{i} ': ' curAnalysisClass ': ' plotMethods{p}]);
%                 plotInd = plotInd + 1;
%             end
        end
    end
end


