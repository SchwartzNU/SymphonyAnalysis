function [crossValModel, errorRate, resultTable] = CellSeparator_1D(T, xVar, labelVar, labelA)
labelVec = T.(labelVar);
if iscategorical(labelVec)
    labelVec = string(labelVec);
end
classVal = startsWith(labelVec, labelA);
X = T.(xVar);

%outlier removal
X(isinf(X)) = nan;
out_x = X > nanmean(X) + nanstd(X)*5 | X < nanmean(X) - nanstd(X)*5;

X(out_x) = 0;
X(isnan(X)) = 0; %set nan to zero for now

linModel = fitcsvm(X, classVal);
crossValModel = crossval(linModel, 'kFold', 10);
errorRate = kfoldLoss(crossValModel);

prediction = kfoldPredict(crossValModel);
dlmwrite('valueDist.txt', X);

allTypes = unique(T.cellType);
if iscategorical(allTypes)
    allTypes = string(allTypes);
end
fullTypeList = T.cellType;
if iscategorical(fullTypeList)
    fullTypeList = string(fullTypeList);
end
%keyboard;
Ntypes = length(allTypes);
fractionCorrect = zeros(Ntypes, 1);
wrongCellIDs = cell(Ntypes, 1);
for i=1:Ntypes
    curType = allTypes{i};
    typeInd = startsWith(fullTypeList, curType);
    curTable = T(typeInd, :);
    
    NofType = sum(typeInd);
    
    correctClass = classVal(find(typeInd==1,1));
    curPrediction = prediction(typeInd);
    Ncorrect = sum(curPrediction == correctClass);
    wrongInd = curPrediction ~= correctClass;
    if sum(strcmp(T.Properties.VariableNames, 'cellID')) > 0
        wrongCellIDs{i} = curTable(wrongInd,:).cellID;
    else
        wrongCellIDs{i} = curTable(wrongInd,:).cellName;
    end
    
    fractionCorrect(i) = Ncorrect./NofType;
end

resultTable = table(allTypes, fractionCorrect, wrongCellIDs, 'VariableNames', {'CellType', 'FractionCorrect', 'WrongCellIDs'});
