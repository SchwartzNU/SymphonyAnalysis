function [dataScoresMean, boundX, boundY] = extractDecisionBoundaryFromModel(M)
% Predict scores over the grid
Xvals = M.X(:,1);
Yvals = M.X(:,2);

nDataPoints = length(Xvals);

nSpaces = 50;
X = linspace(min(Xvals),max(Xvals),nSpaces);
Y = linspace(min(Yvals),max(Yvals),nSpaces);

[x1Grid,x2Grid] = meshgrid(X,Y);
xGrid = [x1Grid(:),x2Grid(:)];

nPoints = length(xGrid);
nModels = length(M.Trained);
scores = zeros(nModels, nPoints);
dataScores = zeros(nModels, nDataPoints);

for i=1:nModels
    scores(i,:) = predict(M.Trained{i},xGrid)';
    dataScores(i,:) = predict(M.Trained{i},[Xvals, Yvals])';
end

dataScoresMean = mean(dataScores, 1);

scoresMean = mean(scores, 1);
scoresMean = reshape(scoresMean, [nSpaces, nSpaces]);
figure(2);
conMatrix = contour(X, Y, scoresMean);
conStruct = contourdata(conMatrix);

conLevels = [conStruct.level];
[~, ind] = min(abs(conLevels - 0.5)); %decision boundary at 0.6 ???
boundX = conStruct(ind).xdata;
boundY = conStruct(ind).ydata;
