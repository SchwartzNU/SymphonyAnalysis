function errVal = raisedCosineFitter_single(params, PSTH_y, exclusionZone)
span = length(PSTH_y);
fitVals = raisedCosine(params, span);
if sum(fitVals(exclusionZone)) > 0
    errVal = inf; %disallow overlap
elseif sum(isinf(fitVals)) == length(fitVals) %all inf
    errVal = inf;
else
    errVal = sum((fitVals - PSTH_y).^2);
end
