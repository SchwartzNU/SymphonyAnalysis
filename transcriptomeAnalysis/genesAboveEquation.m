function [ind, x, y] = genesAboveEquation(xvals, yvals, a, b, lowThres, highThres)

x = linspace(min(xvals), max(xvals), 200);
y = exp(-a*(x - b)) + lowThres;

y_hat = interp1(x, y, xvals);

ind = find(yvals>y_hat & yvals < highThres);