function paramOverlapManyND_SVM_comb(analysisTree, paramList, cellTypeList, testAll, errThreshold)
%paramList: Greg's format is [L1 L2 L3] = getParameterListByType(nodeData);
%Adam's format is L = adaptParamList(nodeData).
%Here use Adam's.

if nargin<4
    testAll = true;
end

[cellTypeList, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList);

N = length(cellTypeList)
if testAll
    groupIndexList = [];
    for i=1:floor(N/2)
        tempVec = [zeros(1,i), ones(1,N-i)];
        groupIndexList = [groupIndexList; unique(perms(tempVec), 'rows')];
    end
else
   groupIndexList = [0, ones(1,N-1)];
end

Ngroups = size(groupIndexList, 1);
numParams = length(paramList)

paramSet = cell(1,N);

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    for ind = 1:N
        if ~isempty( strfind(curCellType, cellTypeList{ind}))
            curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
            [~, paramSet{ind}] = allParamsAcrossCells(curCellTypeTree, paramList);
        end;
    end;
end;

% Make matrices with only the scalar parameters
% Deal with vector parameters later...
% for I = 1:(size(paramForMainCellType,1) * size(paramForMainCellType,2))
%     %Shouldn't be any empty parameter values (but there are...)
%     if isempty(paramForMainCellType{I})
%         paramForMainCellType{I} = NaN;
%     end;
% end;
% %

paramSetMATS = cell(N,1);

for ind = 1:N
    for I = 1:(size(paramSet{ind},1) * size(paramSet{ind},2))
        %Shouldn't be any empty parameter values (but there are...)
        if isempty(paramSet{ind}{I})
            paramSet{ind}{I} = NaN;
        end;
    end;
    paramSetMATS{ind} = cell2mat(paramSet{ind});
end
% % %

%contstruct the Training and Group variables for svntrain: all possible
%pairs (for now, extend to higher dimensions later)

TrainingMAT = [];
GroupsMAT = [];
%accumulate training matrix
for i=1:length(paramSetMATS)
    curMat =  paramSetMATS{i};
    numCells_curType = size(curMat, 2);
    TrainingMAT = [TrainingMAT; curMat'];
    GroupsMAT = [GroupsMAT; i*ones(numCells_curType, 1)];
end

trainingMean = mean(TrainingMAT, 1);
includedCols = find(~isnan(trainingMean) & ~isinf(trainingMean) & trainingMean ~= 0);
C = combnk(includedCols, 2);
numPlanes = size(C, 1);


f1 = figure(1);
f2 = figure(2);
for g=1:Ngroups
    oneInd = find(groupIndexList(g,:) == 1);
    zeroInd = find(groupIndexList(g,:) == 0);
    GroupsMAT_temp = ismember(GroupsMAT, oneInd);
    oneGroupTypes = cellTypeList(oneInd);
    zeroGroupTypes = cellTypeList(zeroInd);
    
    for i=1:numPlanes
        disp([num2str(g) ' of ' num2str(Ngroups) ' groups']);
        disp([num2str(i) ' of ' num2str(numPlanes) ' param pairs']);
        TrainingMAT_part = TrainingMAT(:, C(i,:));
        %linear
        trained = false;
        try
            %figure(f1);
            SVMstruct_lin = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', 'linear', 'showplot', false);   
            trained = true;
        catch
            disp('training error');
        end
        if trained
            Group_classified_lin = svmclassify(SVMstruct_lin,TrainingMAT_part);
            numErrors_lin = sum(abs(GroupsMAT_temp - Group_classified_lin)) %anything not 0 is an error
            if numErrors_lin<=errThreshold
                figure(f1);
                SVMstruct_lin = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', 'linear', 'showplot', true);
                xlabel(paramList{C(i,1)}, 'Interpreter', 'none');
                ylabel(paramList{C(i,2)}, 'Interpreter', 'none');
                title(['Lin: 0: ' zeroGroupTypes' ' 1: ' oneGroupTypes']);
                disp([paramList{C(i,1)},';  ',paramList{C(i,2)}]);
                pause;
            else
                clf(f1)
            end
        end
%         %quad
        trained = false;
        try
            %figure(f2);
            SVMstruct_quad = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', 'quadratic', 'showplot', false);   
            trained = true;
        catch
            disp('training error');
        end
        if trained
            Group_classified_quad = svmclassify(SVMstruct_quad,TrainingMAT_part);
            numErrors_quad = sum(abs(GroupsMAT_temp - Group_classified_quad)) %anything not 0 is an error
            if numErrors_quad<=errThreshold  
                figure(f2);
                SVMstruct_quad = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', 'quadratic', 'showplot', true);
                xlabel(paramList{C(i,1)}, 'Interpreter', 'none');
                ylabel(paramList{C(i,2)}, 'Interpreter', 'none');
                title(['Quad: 0: ' zeroGroupTypes' ' 1: ' oneGroupTypes']);
                disp([paramList{C(i,1)},';  ',paramList{C(i,2)}]);
                pause;
            else
                clf(f2)
            end
        end
    end
    
end





