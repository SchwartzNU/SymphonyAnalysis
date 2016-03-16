function histogramInfo = paramOverlapMany(analysisTree, mainCellType, paramList, cellTypeList, Nbins) 
%VERSION 2

global TYPOLOGY_FILES_FOLDER;
pathname = TYPOLOGY_FILES_FOLDER;

%paramList: Greg's format is [L1 L2 L3] = getParameterListByType(nodeData);
%Adam's format is L = adaptParamList(nodeData). 
%Here use Adam's.


[cellTypeList, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList);

otherCellTypes = cellTypeList(~strcmp(cellTypeList,mainCellType)); %+Comment any irrelevant types in list above
numOtherTypes = length(otherCellTypes);
numParams = length(paramList);


%Collect parameter data
paramForMainCellType = cell(1);
paramForOtherTypes = cell(1,numOtherTypes);
N1 = 0; N2 = zeros(numOtherTypes,1);
%cellNamesOtherTypes

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    disp(curCellType);
    if ~isempty( strfind(curCellType, mainCellType))
        curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
        %given cell type, ALL PARAMETERS
        [cellNamesMainType, paramForMainCellType] = allParamsAcrossCells(curCellTypeTree, paramList);
        N1 = length(cellNamesMainType);
    else
        for otherTypeInd = 1:numOtherTypes
            if ~isempty( strfind(curCellType, otherCellTypes{otherTypeInd}))
                curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));               
                [cellNamesOtherTypes{otherTypeInd}, paramForOtherTypes{otherTypeInd}] = allParamsAcrossCells(curCellTypeTree, paramList);
                N2(otherTypeInd) = length(cellNamesOtherTypes{otherTypeInd});
            end;
        end;
    end;
 
end;    

disp(['number of cells: ',num2str(N1+sum(N2))]);



% Make matrices with only the scalar parameters
% Deal with vector parameters later...

for I = 1:(size(paramForMainCellType,1) * size(paramForMainCellType,2))
    %Shouldn't be any empty parameter values (but there are...)
    if isempty(paramForMainCellType{I})
        paramForMainCellType{I} = NaN;
    end;
end;

paramForMainCellTypeMAT = cell2mat(paramForMainCellType);
paramForOtherTypesMATS = cell(numOtherTypes,1);
for otherTypeInd = 1:numOtherTypes
    
    for I = 1:(size(paramForOtherTypes{otherTypeInd},1) * size(paramForOtherTypes{otherTypeInd},2))
        %Shouldn't be any empty parameter values (but there are...)
        if isempty(paramForOtherTypes{otherTypeInd}{I})
            paramForOtherTypes{otherTypeInd}{I} = NaN;
        end;
    end;
    
    paramForOtherTypesMATS{otherTypeInd} = cell2mat(paramForOtherTypes{otherTypeInd});
end;
% % %






%Make histograms and estimate inter-celltype difference
overlaps = zeros(numParams,1);
M_other = cell(numOtherTypes);
histogramInfo = cell(numParams,1);

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
        if paramInd == 1
            figure;
        end;
        subplotFigure(paramInd, numParams, 6);
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
           set(bar1(otherTypeInd+1),'DisplayName', otherCellTypes{otherTypeInd},'EdgeColor', [0 0 0]); 
        end;
        title(paramList{paramInd});
        
        % % export histogram info (H holds info of a single plot)
        H.histYvectors = [yMain; yOther]'; 
        H.histCenters = centers';
        H.histTitle = paramList{paramInd};
        H.histLegend = [mainCellType; otherCellTypes];
        H.numberOfCells = [N1; N2];
        
        H.cellNamesByType = [{cellNamesMainType}; cellNamesOtherTypes'];
        singleParamDataByType = cell(1+numOtherTypes, 1);
        singleParamDataByType{1} = [paramForMainCellType{paramInd,:}];
        for otherTypeInd = 1:numOtherTypes
            singleParamDataByType{otherTypeInd+1} = [paramForOtherTypes{otherTypeInd}{paramInd,:}];
        end;
        H.singleParamDataByType = singleParamDataByType;
        
        
        histogramInfo{paramInd} = H;
        % % %
        
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
% filename = ['overlapManyV2_',mainCellType,'_',D];
% fullfilename = [pathname, filename,'.mat'];
%save(fullfilename, 'sortedOverlaps', 'paramList', 'mainCellType', 'cellNamesMainType','paramForMainCellType','otherCellTypes','cellNamesOtherTypes','paramForOtherTypes');        

end



