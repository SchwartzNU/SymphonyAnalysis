function [crossValModel, errorRate, resultTable] = CellSeparator_2D_polynomial(T, xVar, yVar, labelVar, labelA, order)
labelVec = T.(labelVar);
if iscategorical(labelVec)
    labelVec = string(labelVec);
end
classVal = startsWith(labelVec, labelA);
X = T.(xVar);
Y = T.(yVar);

%outlier removal
X(isinf(X)) = nan;
Y(isinf(Y)) = nan;
out_x = X > nanmean(X) + nanstd(X)*5 | X < nanmean(X) - nanstd(X)*5;
out_y = Y > nanmean(Y) + nanstd(Y)*5 | Y < nanmean(Y) - nanstd(Y)*5;

X(out_x) = 0;
Y(out_y) = 0;
X(isnan(X)) = 0; %set nan to zero for now
Y(isnan(Y)) = 0;

linModel = fitcsvm([X, Y], classVal, 'KernelFunction', 'polynomial', 'polynomialOrder', order, ...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName',...
    'expected-improvement-plus'));

crossValModel = crossval(linModel, 'kFold', 10);
figure(1);
scatter(X,Y, [], classVal, 'filled');

dlmwrite('scatterPlot.txt', [X Y]);

errorRate = kfoldLoss(crossValModel);

prediction = kfoldPredict(crossValModel);

allTypes = unique(T.cellType);
if iscategorical(allTypes)
    allTypes = string(allTypes);
end
fullTypeList = T.cellType;
if iscategorical(fullTypeList)
    fullTypeList = string(fullTypeList);
end
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
