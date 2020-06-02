function [totalLen, allLines] = drawTree(allPoints, c, ax, doPlot)
if nargin<4
    doPlot = 0;
end
if doPlot
    if isempty(ax)
        f = figure;
        ax = axes('Parent', f);axis equal;
    end
end
allLines = [];
if doPlot
    hold(ax, 'on');
    scatter(allPoints{1}(1), allPoints{1}(2), 'ko', 'markerfacecolor', 'k');
end
totalLen = 0;
for d=2:length(allPoints)
    prevSet = allPoints{d-1};
    curSet = allPoints{d};
    for i=1:size(curSet, 1);
        startPoint = prevSet(curSet(i,3), 1:2);
        endPoint = curSet(i,1:2);
        allLines = [allLines; [startPoint, endPoint]];
        totalLen = totalLen+sqrt((startPoint(1) - endPoint(1))^2 + (startPoint(2) - endPoint(2))^2);
        if doPlot
            line([startPoint(1) endPoint(1)], [startPoint(2) endPoint(2)], ...
                'Color', c, ...
                'marker', 'none', ...
                'markerfacecolor', 'none');
        end
    end
    
end