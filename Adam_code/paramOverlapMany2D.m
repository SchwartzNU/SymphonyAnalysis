function scatterPlotInfo = paramOverlapMany2D(analysisTree, mainCellType, paramList, cellTypeList) 
%1/7/2015. Version 2

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



% %save
% mainCellType(strfind(mainCellType,' ')) = '';
% mainCellType(strfind(mainCellType,'/')) = '';
% mainCellType(strfind(mainCellType,'-')) = '';
% 
% D  = datestr(date);
% D(D == '-') = '';
% filename = ['overlapMany2D_',mainCellType,'_',D];
% fullfilename = [pathname, filename,'.mat'];
% save(fullfilename, 'paramList', 'mainCellType', 'cellNamesMainType','paramForMainCellType','otherCellTypes','cellNamesOtherTypes','paramForOtherTypes');


%Make 2D plots.
numParameterPairs = numParams.*(numParams-1)./2;
paramPairCount = 0;
scatterPlotInfo = cell(numParameterPairs,1);
%figure;

for paramInd1 = 1:numParams-1
    MmainParam1 = paramForMainCellTypeMAT(paramInd1,:);
    %MmainParam1 = MmainParam1(~isnan(MmainParam1) & ~(MmainParam1==inf));
    for otherTypeInd = 1:numOtherTypes
        M2 = paramForOtherTypesMATS{otherTypeInd}(paramInd1,:);
        %M2 = M2(~isnan(M2) & ~(M2==inf));
        M_otherParam1{otherTypeInd} = M2;
    end;
    
    for paramInd2 = paramInd1+1:numParams
        MmainParam2 = paramForMainCellTypeMAT(paramInd2,:);
        %MmainParam2 = MmainParam2(~isnan(MmainParam2) & ~(MmainParam2==inf));
        for otherTypeInd = 1:numOtherTypes
            M2 = paramForOtherTypesMATS{otherTypeInd}(paramInd2,:);
            %M2 = M2(~isnan(M2) & ~(M2==inf));
            M_otherParam2{otherTypeInd} = M2;
        end;
        
        if ~all(isnan(MmainParam1)| MmainParam1==inf) && ~all(isnan(MmainParam2)| MmainParam2==inf)
            paramPairCount = paramPairCount+1;
            if paramPairCount == 1
                figure;
            end;
            subplotFigure(paramPairCount, numParameterPairs, 4);
            
            scatter(MmainParam1, MmainParam2, 'DisplayName', mainCellType, 'MarkerFaceColor',[1 0 0],...
                'MarkerEdgeColor',[1 0 0]);
            hold on;
            for otherTypeInd = 1:numOtherTypes
                if ~all(isnan(M_otherParam1{otherTypeInd})| M_otherParam1{otherTypeInd}==inf) && ~all(isnan(M_otherParam2{otherTypeInd})| M_otherParam2{otherTypeInd}==inf)
                    scatter(M_otherParam1{otherTypeInd}, M_otherParam2{otherTypeInd}, 'DisplayName', otherCellTypes{otherTypeInd});
                    title([paramList{paramInd1},' vs ', paramList{paramInd2}]);
                end;
            end; 
            hold off;
            
            % % export scatter plot info (S holds info of a single plot)
            S.Xvectors = [MmainParam1; M_otherParam1']';
            S.Yvectors = [MmainParam2; M_otherParam2']';
            S.plotTitle = [paramList{paramInd1},' vs ', paramList{paramInd2}];
            S.plotLegend = [mainCellType; otherCellTypes];
            S.numberOfCells = [N1; N2];
            
            S.cellNamesByType = [{cellNamesMainType}; cellNamesOtherTypes'];
            paramXdataByType = cell(1+numOtherTypes, 1);
            paramYdataByType = cell(1+numOtherTypes, 1);
            paramXdataByType{1} = [paramForMainCellType{paramInd1,:}];
            paramYdataByType{1} = [paramForMainCellType{paramInd2,:}];
            for otherTypeInd = 1:numOtherTypes
                paramXdataByType{otherTypeInd+1} = [paramForOtherTypes{otherTypeInd}{paramInd1,:}];
                paramYdataByType{otherTypeInd+1} = [paramForOtherTypes{otherTypeInd}{paramInd2,:}];
            end;
            S.paramXdataByType = paramXdataByType;
            S.paramYdataByType = paramYdataByType; 
            
            scatterPlotInfo{paramPairCount} = S;
            % % %
        end;
    end;
end;

% Create legend
legend1 = legend('show');
set(legend1,'FontSize',12);

end



