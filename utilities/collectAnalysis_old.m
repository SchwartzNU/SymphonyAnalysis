function collectAnalysis(analysisClassName, nameSuffix, cellNames)
%analyzeCell must be run first. This will only load already created
%analysis trees and graft them together.
%It will run analyzeCell for you if there is no analysis tree for this cell

global ANALYSIS_FOLDER
if nargin < 3
    cellNames = [];
end
if nargin < 2
    nameSuffix = 'allCells';
end

fid = fopen([ANALYSIS_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

cellDataDir = [ANALYSIS_FOLDER 'cellData/'];
D_cell = dir(cellDataDir);

analysisTree = AnalysisTree;
nodeData.name = ['Multi cell analysis tree: ' nameSuffix ': ' analysisClassName];
analysisTree = analysisTree.set(1, nodeData);

z = 1;
for i=1:length(D_cell)
    if strfind(D_cell(i).name, '.mat')
        if ~isempty(cellNames)
            if any(strmatch(D_cell(i).name, cellNames))
                [allCellDataNames{z}, ~] = strtok(D_cell(i).name, 'mat');
                z=z+1;
            end
        else
            [allCellDataNames{z}, ~] = strtok(D_cell(i).name, '.mat');
            z=z+1;
        end
    end
end
    
Ncells = length(allCellDataNames);
for i=1:Ncells
    curCellName = allCellDataNames{i}
    load([ANALYSIS_FOLDER 'cellData/' allCellDataNames{i}]);
    
    %check for 2 amps
    if cellData.epochs(1).attributes.isKey('amp2Mode') %will fail for current IV protocol - fix this!
        twoAmps = true;
    else
        twoAmps = false;
    end
    
    %todo: deal with cell names containing -Ch2 here!
    
    T = [];
    T2 = [];
    disp('loading analyses');
    %try to load existing analysis trees
    disp(curCellName)
    if exist([ANALYSIS_FOLDER 'analysisTrees/' curCellName '.mat'], 'file')
        load([ANALYSIS_FOLDER 'analysisTrees/' curCellName]);
        T = cellAnalysisTree;
    end
    if twoAmps
        if exist([ANALYSIS_FOLDER 'analysisTrees/' curCellName '-Ch2.mat'], 'file')
            load([ANALYSIS_FOLDER 'analysisTrees/' curCellName '-Ch2']);
            T2 = cellAnalysisTree_Ch2;
        end
    end
    %T
    %T2
    %pause;
    
    if isempty(T) || (twoAmps && isempty(T2))
        disp('running analyzeCell');
        analyzeCell(curCellName, true, false);
        if exist([ANALYSIS_FOLDER 'analysisTrees/' curCellName '.mat'], 'file')
            load([ANALYSIS_FOLDER 'analysisTrees/' curCellName]);
            T = cellAnalysisTree;
        end
        if twoAmps
            if exist([ANALYSIS_FOLDER 'analysisTrees/' curCellName '-Ch2.mat'], 'file')
                load([ANALYSIS_FOLDER 'analysisTrees/' curCellName '-Ch2']);
                T2 = cellAnalysisTree_Ch2;
            end
        end
    end
    
    %find correct analysis trees
    if ~isempty(T) && (~twoAmps || ~isempty(T2))
        disp('collecting data sets');
        chInd = T.getchildren(1);
        for c=1:length(chInd)
            nameParts = textscan(T.get(chInd(c)).name, '%s', 'delimiter', ':');
            curClassName = strtrim(nameParts{1}{3});
            if strcmp(curClassName, analysisClassName)
                disp('found match');
                analysisTree = analysisTree.graft(1, T.subtree(chInd(c)));
                if twoAmps
                    analysisTree = analysisTree.graft(1, T2.subtree(chInd(c)));
                end
            end
        end
    end
end

save([ANALYSIS_FOLDER 'analysisTrees/' analysisClassName '_' nameSuffix], 'analysisTree');


%plotting
% if doPlots
%     plotInd = 1;
%     chInd = cellAnalysisTree.getchildren(1);
%     for i=1:length(chInd)
%         curNode = cellAnalysisTree.subtree(chInd(i));
%         curNodeData = curNode.get(1);
%         curName = curNodeData.name;
%         [~, str] = strtok(curName, ':');
%         [~, str] = strtok(str, ':');
%         [str, ~] = strtok(str, ':');
%         curAnalysisClass = strtrim(str);
%         
%         allMethods = methods(curAnalysisClass);
%         plotMethods = allMethods(strmatch('plot', allMethods));
%         plotMethods = plotMethods(~strcmp(plotMethods, 'plot'));
%         
%         for p=1:length(plotMethods)
%             figHandles(plotInd) = figure(plotInd);
%             eval([curAnalysisClass '.' plotMethods{p} '(curNode, cellData)']);
%             set(figHandles(plotInd), 'Name', [dataSetKeys{i} ': ' curAnalysisClass ': ' plotMethods{p}]);
%             plotInd = plotInd + 1;
% %             if twoAmps
% %                 figHandles(plotInd) = figure(plotInd);
% %                 eval(['T2.' plotMethods{p} '(curNode, cellData)']);
% %                 set(figHandles(plotInd), 'Name',  ['Ch2: ' dataSetKeys{i} ': ' curAnalysisClass ': ' plotMethods{p}]);
% %                 plotInd = plotInd + 1;
% %             end
%         end
%     end
% end


