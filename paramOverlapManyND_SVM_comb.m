function [SVMstructs, predictions, param1, param2, paramVals, lineCoeffs, minErrs] = paramOverlapManyND_SVM_comb(analysisTree, paramList, cellTypeList, testAll)
%paramList: Greg's format is [L1 L2 L3] = getParameterListByType(nodeData);
%Adam's format is L = adaptParamList(nodeData).
%Here use Adam's.

kernelType = 'linear';

if nargin<4
    testAll = true;
end

[~, paramList] = narrowDownLists(analysisTree,cellTypeList, paramList);

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
for g=1:Ngroups
    oneInd = find(groupIndexList(g,:) == 1);
    zeroInd = find(groupIndexList(g,:) == 0);
    GroupsMAT_temp = ismember(GroupsMAT, oneInd);
    oneGroupTypes = cellTypeList(oneInd);
    zeroGroupTypes = cellTypeList(zeroInd);
    
    lossVals = NaN*ones(1,numPlanes);
    numErrs = NaN*ones(1,numPlanes);
    for i=1:numPlanes
        disp([num2str(g) ' of ' num2str(Ngroups) ' groups']);
        disp([num2str(i) ' of ' num2str(numPlanes) ' param pairs']);
        TrainingMAT_part = TrainingMAT(:, C(i,:));
        %linear
        trained = false;
        try
            %figure(f1);
            SVMstruct = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', kernelType, 'showplot', false);
            %SVMstruct_lin = fitcsvm(TrainingMAT_part, GroupsMAT_temp, 'KernelFunction', kernelType);
            trained = true;
        catch
            disp('training error');
        end
        if trained          
            prediction = svmclassify(SVMstruct, TrainingMAT_part);
            numErrs(i) = sum(abs(GroupsMAT_temp - prediction));
        end
%         %quad
%        trained = false;
%         try
%             %figure(f2);
%             SVMstruct_quad = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', 'quadratic', 'showplot', false);   
%             trained = true;
%         catch
%             disp('training error');
%         end
%         if trained
%             Group_classified_quad = svmclassify(SVMstruct_quad,TrainingMAT_part);
%             numErrors_quad = sum(abs(GroupsMAT_temp - Group_classified_quad)) %anything not 0 is an error
%             if numErrors_quad<errorThres  
%                 figure(f2);
%                 SVMstruct_quad = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', 'quadratic', 'showplot', true);
%                 xlabel(paramList{C(i,1)}, 'Interpreter', 'none');
%                 ylabel(paramList{C(i,2)}, 'Interpreter', 'none');
%                 title(['Quad: 0: ' zeroGroupTypes' ' 1: ' oneGroupTypes']);
%                 pause;
%             else
%                 clf(f2)
%             end
%         end
    end   
    [minErrs, minInd] = min(numErrs)
    for i=1:length(minInd)        
        curInd = minInd(i);
        TrainingMAT_part = TrainingMAT(:, C(curInd,:));
        %for plotting
        figure(1);
        SVMstruct = svmtrain(TrainingMAT_part, GroupsMAT_temp, 'kernel_function', kernelType, 'showplot', true);
        SVMstructs(i) = SVMstruct;

        w1 = dot(SVMstruct.Alpha, SVMstruct.SupportVectors(:,1));
        w2 = dot(SVMstruct.Alpha, SVMstruct.SupportVectors(:,2));        
        % with line given as y = a*x + b
        a = -w1/w2;
        b = -SVMstruct.Bias/w2;        
        a_scaled = a * SVMstructs.ScaleData.scaleFactor(1) / SVMstructs.ScaleData.scaleFactor(2);
        b_scaled = b * SVMstructs.ScaleData.scaleFactor(2) + SVMstructs.ScaleData.shift(2);
        lineCoeffs(i,:) = [a_scaled, b_scaled]; %equation of the separating line        
        
        xlabel(paramList{C(curInd,1)}, 'Interpreter', 'none');
        ylabel(paramList{C(curInd,2)}, 'Interpreter', 'none');
        title([kernelType ' 0: ' zeroGroupTypes' ' 1: ' oneGroupTypes']);       
        param1{i} = paramList{C(curInd,1)};
        param2{i} = paramList{C(curInd,2)};
        paramVals{i} = TrainingMAT_part;
        predictions{i} = svmclassify(SVMstructs, TrainingMAT_part);
        pause;
    end
end


