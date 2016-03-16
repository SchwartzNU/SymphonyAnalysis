function functionOverlapMany(analysisTree, analysisClass, mainCellType, paramList, cellTypeList) 

global TYPOLOGY_FILES_FOLDER;
pathname = TYPOLOGY_FILES_FOLDER;


otherCellTypes = cellTypeList(~strcmp(cellTypeList,mainCellType)); %+Comment any irrelevant types in list above


numParams = length(paramList);
numOtherTypes = length(otherCellTypes);



% % next lines remove cell types from the list that were not found in the tree
otherCellTypesFound = cell(0);
cellTypeNodes = analysisTree.getchildren(1);
for otherTypeInd = 1:numOtherTypes
    for nodeInd = 1:length(cellTypeNodes)
        curCellType = analysisTree.Node{cellTypeNodes(nodeInd)}.name;
        if ~isempty( strfind(curCellType, otherCellTypes{otherTypeInd}))
            otherCellTypesFound = [otherCellTypesFound; otherCellTypes{otherTypeInd}];
        end;
    end;
end;
otherCellTypesFound = unique(otherCellTypesFound);
otherCellTypes = otherCellTypesFound;
numOtherTypes = length(otherCellTypes);
% %



%Collect parameter data
paramForMainCellType = cell(1,numParams);
paramForOtherTypes = cell(numOtherTypes, numParams);
%cellNamesOtherTypes

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    disp(curCellType)
    if ~isempty( strfind(curCellType, mainCellType))
        curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
        for YparamInd = 1:length(paramList)            
            YparamName = paramList{YparamInd};
            %given cell type, given parameter
            [cellNamesMainType, paramForMainCellType{YparamInd}] = functionAcrossCells(curCellTypeTree, analysisClass, YparamName);
        end;
        
    else
        for otherTypeInd = 1:numOtherTypes
            if ~isempty( strfind(curCellType, otherCellTypes{otherTypeInd}))
                curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
                for YparamInd = 1:length(paramList)
                    YparamName = paramList{YparamInd};
                    [cellNamesOtherTypes{otherTypeInd}, paramForOtherTypes{otherTypeInd, YparamInd}] = functionAcrossCells(curCellTypeTree, analysisClass, YparamName);
                end;

            end;
        end;
    end;
 
end;    


% %save
mainCellType(strfind(mainCellType,' ')) = '';
mainCellType(strfind(mainCellType,'/')) = '';
mainCellType(strfind(mainCellType,'-')) = '';
D  = datestr(date);
D(D == '-') = '';
filename = ['functionOverlapMany_',mainCellType,'_',D];
fullfilename = [pathname, filename,'.mat'];
save(fullfilename, 'paramList', 'mainCellType', 'cellNamesMainType','paramForMainCellType','otherCellTypes','cellNamesOtherTypes','paramForOtherTypes');




%Make plots
figure;
colorScale = parula(numOtherTypes+1);
for YparamInd = 1:numParams
    if numParams < 3
        subplot1 = subplot(1, numParams, YparamInd);
    else
        subplot1 = subplot(ceil(numParams/3), 3, YparamInd);
    end;
    hold on;
    mainTypeParam = paramForMainCellType{YparamInd};
    for cellInd = 1:length(mainTypeParam)
        X = mainTypeParam{cellInd}(1,:);
        Y = mainTypeParam{cellInd}(2,:);
        if ~isempty( strfind(paramList{YparamInd}, 'Spikes')) || ~isempty( strfind(paramList{YparamInd}, 'FR') )
            Y = Y./max(Y);
        end;
        plot(X, Y, 'Color', [1 0 0])
    end;
    
    for otherTypeInd = 1:numOtherTypes
        otherTypeParam = paramForOtherTypes{otherTypeInd,YparamInd};
        for cellInd = 1:length(otherTypeParam)
            if ~isempty(otherTypeParam{cellInd})
                X = otherTypeParam{cellInd}(1,:);
                Y = otherTypeParam{cellInd}(2,:);
                if ~isempty( strfind(paramList{YparamInd}, 'Spikes')) || ~isempty( strfind(paramList{YparamInd}, 'FR') )
                    Y = Y./max(Y);
                end;
                plot(X, Y, 'Color', colorScale(otherTypeInd,:))
            end;
        end;
    end;
    title(paramList{YparamInd});
    hold off;
end;
    

% 
% % Create legend
% legend1 = legend('show');
% set(legend1,'FontSize',12);


end



