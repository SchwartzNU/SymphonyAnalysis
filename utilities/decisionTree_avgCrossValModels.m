%% part 1
function [ avgCrossValModels ] = decisionTree_avgCrossValModels( curr_crossValModel, dt_testSet_stim, xVar, yVar, currCell )
%xvar and yvar need to be 'strings' 
resultTable = [];

for iter = 1:10
    resultTable(iter) = predict(curr_crossValModel.Trained{iter}, [dt_testSet_stim.(xVar)(currCell) dt_testSet_stim.(yVar)(currCell)]); 
end

if mean(resultTable) > .5
    avgCrossValModels = 1;
else
    avgCrossValModels = 0;
end

end
