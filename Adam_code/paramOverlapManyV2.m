function paramOverlapManyV2(analysisTree, mainCellType, paramList, cellTypeList, Nbins) 

userDate = '122614';
pathname = ['/Users/adammani/Documents/analysis/Adam Matlab analysis/',userDate,'/mat files/'];



[cellTypeList, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList);

otherCellTypes = cellTypeList(~strcmp(cellTypeList,mainCellType)); %+Comment any irrelevant types in list above
numOtherTypes = length(otherCellTypes);
numParams = length(paramList);


%Collect parameter data
paramForMainCellType = cell(1);
paramForOtherTypes = cell(1,numOtherTypes);
%cellNamesOtherTypes

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    disp(curCellType);
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

% %save
mainCellType(strfind(mainCellType,' ')) = '';
mainCellType(strfind(mainCellType,'/')) = '';
mainCellType(strfind(mainCellType,'-')) = '';

filename = ['overlapMany_',mainCellType,'_',userDate];
fullfilename = [pathname, filename,'.mat'];
save(fullfilename, 'sortedOverlaps', 'paramList', 'mainCellType', 'cellNamesMainType','paramForMainCellType','otherCellTypes','cellNamesOtherTypes','paramForOtherTypes');        

end



