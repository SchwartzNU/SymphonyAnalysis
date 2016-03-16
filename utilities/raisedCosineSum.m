function fitVals = raisedCosineSum(params, N, span)
for i=1:N
    w(i) = round(params((i-1)*3 + 1));
    h(i) = params((i-1)*3 + 2);
    offset(i) = round(params((i-1)*3 + 3));
end

fitMatrix = zeros(N, span);

for i=1:N
    fitMatrix(i,:) = rcos(span, w(i), h(i), offset(i));
end
fitVals = sum(fitMatrix, 1);

%discourage overlap
% fitMins = min(fitMatrix, [], 1);
% fitVals = sum(fitMatrix, 1);
% fitVals(fitMins>0) = Inf;