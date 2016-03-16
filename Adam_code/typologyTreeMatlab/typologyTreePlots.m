function plotsByNode = typologyTreePlots(tTree, excludedNodeId)
%Adam 1/14/15


load('treeLS_newProj_011915.mat');
treeLS = analysisTree;
load('treeFB_newProj_011915.mat');
treeFB = analysisTree;
load('treeSMS_newProj_011915.mat');
treeSMS = analysisTree;
load('treeMB_newProj_011915.mat');
treeMB = analysisTree;
load('treeMB8000_newProj_011915.mat');
treeMB8000 = analysisTree;
load('treeMB500_newProj_011915.mat');
treeMB250 = analysisTree;

[nodeId, nodeCelltypeList, nodeConditions] = getSearchIndex(tTree);

plotsByNode = cell(length(tTree.Node),1);
nodeNcells = zeros(length(tTree.Node),1);
for I =1:length(tTree.Node)
    if ~tTree.isleaf(I) && isempty(find(excludedNodeId == nodeId(I)))
        curNodeTypeList = nodeCelltypeList{I};
        ch = tTree.getchildren(I);
        curChildCondition = nodeConditions{ch(1)};
        [analysisTreeName, curNodeParamList, twoD] = conditionParser(curChildCondition);
        for cellOnList = 1:length(curNodeTypeList)
            %Silly hack, done because paramOverlapMany can't have as the main
            %cell type a cell that is not in the analysis tree.
            if twoD
                H = paramOverlapMany2D(eval(analysisTreeName),curNodeTypeList{cellOnList}, curNodeParamList, curNodeTypeList);
            else
                H = paramOverlapMany(eval(analysisTreeName),curNodeTypeList{cellOnList}, curNodeParamList, curNodeTypeList,20);
            end;
            if ~isempty(H)
                break;
            end;
        end;
%         H.nodeId = nodeId(I);    %Doesn't work, overwrites H???
%         H.twoD = twoD;
        if ~isempty(H)
            plotsByNode{I} = H;
            nodeNcells(I) = sum(H{1}.numberOfCells);
            % Create textbox - display node id
            annotation(gcf,'textbox',[0.15 0.9 0.1 0.1],...
                'String',{['node ID = ',num2str(nodeId(I)),'   n = ',num2str(nodeNcells(I))]},...
                'FontSize',14,...
                'EdgeColor','none');
        else
            plotsByNode{I} = {'ERROR: check parameter naming...'}; 
        end;
        disp(num2str(nodeId(I)));
        %keyboard;
    end;
end;
