function subplotFigure(plotIndex, numPlots, maxPlotsPerFig)
%12/30/14

%maxPlotsPerFig = 6;
numPlotsWidth = 2;

if numPlots < numPlotsWidth
    subplot(1, numPlots, plotIndex);
else
    figInd = ceil(plotIndex/maxPlotsPerFig);
    %figure(figInd+10);
    plotIndexCurFigure = plotIndex - maxPlotsPerFig*(figInd - 1);
    subplot(ceil(maxPlotsPerFig/numPlotsWidth), numPlotsWidth , plotIndexCurFigure);
end;