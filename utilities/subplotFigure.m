function subplotFigure(plotIndex, numPlots, maxPlotsPerFig, numPlotsWidth)
%12/30/14
%Currently doesn't open multiple figures. (otherwise would uncomment line 14)

%maxPlotsPerFig = 6;
if nargin < 4
    numPlotsWidth = 2;
end;

if numPlots < numPlotsWidth
    subplot(1, numPlots, plotIndex);
else
    figInd = ceil(plotIndex/maxPlotsPerFig);
    %figure(figInd+10);
    plotIndexInCurFigure = plotIndex - maxPlotsPerFig*(figInd - 1);
    subplot(ceil(maxPlotsPerFig/numPlotsWidth), numPlotsWidth , plotIndexInCurFigure);
end;