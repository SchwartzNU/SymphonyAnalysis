function paramOverlapManyND_SVM(analysisTree, mainCellType, paramList, cellTypeList)
%paramList: Greg's format is [L1 L2 L3] = getParameterListByType(nodeData);
%Adam's format is L = adaptParamList(nodeData).
%Here use Adam's.

otherCellTypes = cellTypeList(~strcmp(cellTypeList,mainCellType)); %+Comment any irrelevant types in list above
numOtherTypes = length(otherCellTypes)
numParams = length(paramList)

%Collect parameter data
paramForMainCellType = cell(1);
paramForOtherTypes = cell(1,numOtherTypes);
%cellNamesOtherTypes

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    %disp(curCellType);
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
%

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
end
% % %

%contstruct the Training and Group variables for svntrain: all possible
%pairs (for now, extend to higher dimensions later)

numCells_mainType = size(paramForMainCellTypeMAT, 2)
TrainingMAT = paramForMainCellTypeMAT';
GroupsMAT = zeros(numCells_mainType, 1);

for i=1:length(paramForOtherTypesMATS)
    curMat =  paramForOtherTypesMATS{i};
    numCells_curType = size(curMat, 2);
    TrainingMAT = [TrainingMAT; curMat'];
    GroupsMAT = [GroupsMAT; ones(numCells_curType, 1)];
end

trainingMean = mean(TrainingMAT, 1);
includedCols = find(~isnan(trainingMean) & ~isinf(trainingMean) & trainingMean ~= 0);
C = combnk(includedCols, 2);
numPlanes = size(C, 1);

%keyboard;

for i=1:numPlanes
    disp([num2str(i) ' of ' num2str(numPlanes)]);
    TrainingMAT_part = TrainingMAT(:, C(i,:));
    trained = false;
    try
        SVMstruct = svmtrain(TrainingMAT_part, GroupsMAT, 'showplot', true);
        trained = true;
    catch
        disp('training error');
    end
    if trained
        Group_classified = svmclassify(SVMstruct,TrainingMAT_part);
        numErrors = sum(abs(GroupsMAT - Group_classified)) %anything not 0 is an error
        if numErrors<2
            xlabel(paramList{C(i,1)}, 'Interpreter', 'none');
            ylabel(paramList{C(i,2)}, 'Interpreter', 'none');
            pause;
        end
    end    
end






