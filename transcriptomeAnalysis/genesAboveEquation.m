function [ind, x, y] = genesAboveEquation(xvals, yvals, a, b)
lowThres = 0.0089; %2/Ncells

x = linspace(min(xvals), max(xvals), 200);
y = exp(-a*(x - b)) + lowThres;

y_hat = interp1(x, y, xvals);

ind = find(yvals>y_hat);