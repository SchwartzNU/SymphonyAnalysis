function scatterPlotInfo = paramOverlapMany2Dnew(analysisTree, paramList, cellTypeList) 
%1/23/2015. Version 2
%"main cell type" will be the first type on the list of celltypes passed down to
%this function.

% global TYPOLOGY_FILES_FOLDER;
% pathname = TYPOLOGY_FILES_FOLDER;

%paramList: Greg's format is [L1 L2 L3] = getParameterListByType(nodeData);
%Adam's format is L = adaptParamList(nodeData). 
%Here use Adam's.





[cellTypeList, numOfCells, cellNamesByType, paramList, paramByType] = getParamDataFromAnalysisTree(analysisTree, paramList, cellTypeList);
%[cellTypeList, numOfCells, cellNamesByType, paramList, paramByType] = getParamDataFromBigMatrix(dataStruct, paramList, cellTypeList);

mainCellType = cellTypeList{1};
otherCellTypes = cellTypeList(2:end);
paramForMainCellType = paramByType{1};
paramForOtherTypes = paramByType(2:end);
numOtherTypes = length(otherCellTypes);
numParams = length(paramList);

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
            if mod(paramPairCount,1) == 0
                figure;
            end;
            %subplotFigure(paramPairCount, numParameterPairs, 1,1);
            
            scatter(MmainParam1, MmainParam2, 'DisplayName', mainCellType, 'MarkerFaceColor',[1 0 0],...
                'MarkerEdgeColor',[1 0 0]);
            
%             %cell names in plot
%             for pt = 1:length(MmainParam1)
%                 text(MmainParam1(pt), MmainParam2(pt), cellNamesByType{1}{pt});
%             end;
             
            hold on;
            for otherTypeInd = 1:numOtherTypes
                if ~all(isnan(M_otherParam1{otherTypeInd})| M_otherParam1{otherTypeInd}==inf) && ~all(isnan(M_otherParam2{otherTypeInd})| M_otherParam2{otherTypeInd}==inf)
                    scatter(M_otherParam1{otherTypeInd}, M_otherParam2{otherTypeInd}, 'DisplayName', otherCellTypes{otherTypeInd});
                    
%                     %cell names in plot
%                     for pt = 1:length(M_otherParam1{otherTypeInd})
%                         text(M_otherParam1{otherTypeInd}(pt), M_otherParam2{otherTypeInd}(pt), cellNamesByType{otherTypeInd+1}{pt});
%                     end;
                    
                    title([paramList{paramInd1},' vs ', paramList{paramInd2}]);
                end;
            end; 
            hold off;
            
            % % export scatter plot info (S holds info of a single plot)
            S.Xvectors = [MmainParam1; M_otherParam1']';
            S.Yvectors = [MmainParam2; M_otherParam2']';
            S.plotTitle = [paramList{paramInd1},' vs ', paramList{paramInd2}];
            S.plotLegend = cellTypeList;
            S.numberOfCells = numOfCells;
            
            S.cellNamesByType = cellNamesByType;
   
            paramXdataByType = cell(1+numOtherTypes, 1);
            paramYdataByType = cell(1+numOtherTypes, 1);

            for cellTypeInd = 1:numOtherTypes+1
                paramXdataByType{cellTypeInd} = [paramByType{cellTypeInd}{paramInd1,:}];
                paramYdataByType{cellTypeInd} = [paramByType{cellTypeInd}{paramInd2,:}];
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



