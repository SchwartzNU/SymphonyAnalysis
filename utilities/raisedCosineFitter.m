function errVal = raisedCosineFitter(params, N, PSTH_y)
span = length(PSTH_y);
fitVals = raisedCosineSum(params, N, span);
errVal = sum((fitVals - PSTH_y).^2);
