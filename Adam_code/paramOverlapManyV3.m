function paramOverlapManyV3(analysisTrees, mainCellType, paramList, cellTypeList, Nbins) 

global TYPOLOGY_FILES_FOLDER;
pathname = TYPOLOGY_FILES_FOLDER;

numTrees = length(analysisTrees);

cellNamesMainTypeTREES = cell(numTrees,1);
paramForMainCellTypeTREES = cell(numTrees,1);
cellNamesOtherTypesTREES = cell(numTrees,1);
paramForOtherTypesTREES = cell(numTrees,1);

for treeInd = 1:numTrees;
    analysisTree = analysisTrees(treeInd);
    
    
    

    [curCellTypeList, curParamList] = narrowDownLists(analysisTree,cellTypeList, paramList);
    
    otherCellTypes = curCellTypeList(~strcmp(curCellTypeList,mainCellType)); %+Comment any irrelevant types in list above
    numOtherTypes = length(otherCellTypes);
    numParams = length(curParamList);
    
    
    %Collect parameter data
    paramForMainCellType = cell(1);
    paramForOtherTypes = cell(1,numOtherTypes);
    %cellNamesOtherTypes
    
    cellTypeNodes = analysisTree.getchildren(1);
    for cellTypeInd = 1:length(cellTypeNodes)
        curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
        disp(curCellType)
        if ~isempty( strfind(curCellType, mainCellType))
            curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
            %given cell type, ALL PARAMETERS
            [cellNamesMainType, paramForMainCellType] = allParamsAcrossCells(curCellTypeTree, paramList);
        else
            for otherTypeInd = 1:numOtherTypes
                if ~isempty( strfind(curCellType, otherCellTypes{otherTypeInd}))
                    curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
                    [cellNamesOtherTypes{otherTypeInd}, paramForOtherTypes{otherTypeInd}] = allParamsAcrossCells(curCellTypeTree, paramList);
                end;
            end;
        end;
        
    end;
    
    %combine data across trees
    if ~isempty(cellNamesMainType) && ~isempty(cellNamesOtherTypes)
        cellNamesMainTypeTREES{treeInd} = cellNamesMainType;
        paramForMainCellTypeTREES{treeInd} = paramForMainCellType;
        cellNamesOtherTypesTREES{treeInd} = cellNamesOtherTypes;
        paramForOtherTypesTREES{treeInd} = paramForOtherTypes;
    end;
end;

% % %
% NEED TO MATCH trees by cell names...??
% % %



% Make matrices with only the scalar parameters
% Deal with vector parameters later...

paramForMainCellTypeMAT = cell2mat(paramForMainCellType);
paramForOtherTypesMATS = cell(numOtherTypes,1);
for otherTypeInd = 1:numOtherTypes
    paramForOtherTypesMATS{otherTypeInd} = cell2mat(paramForOtherTypes{otherTypeInd});
end;
% % %






%Make histograms and estimate inter-celltype difference
overlaps = zeros(numParams,1);
M_other = cell(numOtherTypes);
figure;

for paramInd = 1:numParams
    MmainParam1 = paramForMainCellTypeMAT(paramInd,:);
    MmainParam1 = MmainParam1(~isnan(MmainParam1) & ~(MmainParam1==inf));
    minM = min(MmainParam1);
    maxM = max(MmainParam1);
    for otherTypeInd = 1:numOtherTypes
        M2 = paramForOtherTypesMATS{otherTypeInd}(paramInd,:);
        M2 = M2(~isnan(M2) & ~(M2==inf));
        M_other{otherTypeInd} = M2;
        if ~isempty(M2)
            minM = min( minM, min(M2));
            maxM = max( maxM, max(M2));
        end;
    end;
    
    
    leftEdge = minM;
    rightEdge = maxM;
    binSize =  (rightEdge - leftEdge)/Nbins;
    centers = (leftEdge:binSize:rightEdge);
    
    if binSize > 0
        if numParams < 3
            subplot1 = subplot(1, numParams, paramInd);
        else
            subplot1 = subplot(ceil(numParams/3), 3, paramInd);
        end;
        yMain = hist(MmainParam1, centers);
        yMain = yMain./sum(yMain);

        yOther = zeros(numOtherTypes, length(centers));
        for otherTypeInd = 1:numOtherTypes
            yOther(otherTypeInd,:) = hist(M_other{otherTypeInd}, centers);
            yOther(otherTypeInd,:) = yOther(otherTypeInd,:)./sum(yOther(otherTypeInd,:));
            if isnan(yOther(otherTypeInd,1)) || yOther(otherTypeInd,1)==inf
                yOther(otherTypeInd,:) = zeros(1, length(yOther(otherTypeInd,:)));
            end;
                
        end;
        
        sumYother = sum(yOther, 1);
        
%         %main type red, all others gray
%         bar1 = bar(centers,[yMain; sumYother]','stacked');
%         set(bar1(1),'FaceColor',[1 0 0]);
%         set(bar1(2),'FaceColor',[0.8 0.8 0.8]);
%         title(paramList{paramInd});
        
        %main type red, others parula
        bar1 = bar(centers,[yMain; yOther]','stacked');
        set(bar1(1),'DisplayName', mainCellType, 'FaceColor',[1 0 0]);
        for otherTypeInd = 1:numOtherTypes
           set(bar1(otherTypeInd+1),'DisplayName', otherCellTypes{otherTypeInd}); 
        end;
        title(paramList{paramInd});
        
        
        %     %calculate obverlap...
        yMain_n = yMain./sqrt(yMain*yMain');
        sumYother_n = sumYother./sqrt(sumYother*sumYother');
        overlaps(paramInd) = yMain_n*sumYother_n';
    end;
    
end;

% Create legend
legend1 = legend('show');
set(legend1,'FontSize',12);

% Display overlaps
[sortedOverlaps, sortedParamIndices] = sort(overlaps);
disp(sortedOverlaps);
paramList = paramList(sortedParamIndices);
disp(paramList);
[minOverlap, minOverlapParamIndex] =  min(sortedOverlaps);
disp(['Minimal ovrlap is: ', num2str(minOverlap),' using: ', paramList{minOverlapParamIndex}]);

% % %save
% mainCellType(strfind(mainCellType,' ')) = '';
% mainCellType(strfind(mainCellType,'/')) = '';
% mainCellType(strfind(mainCellType,'-')) = '';
% 
% D  = datestr(date);
% D(D == '-') = '';
% filename = ['overlapManyV3_',mainCellType,'_',D];
% fullfilename = [pathname, filename,'.mat'];
% save(fullfilename, 'sortedOverlaps', 'paramList', 'mainCellType', 'cellNamesMainType','paramForMainCellType','otherCellTypes','cellNamesOtherTypes','paramForOtherTypes');        

end



