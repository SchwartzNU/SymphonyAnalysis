function [] = writeColorTrace(ax, fname)
ch = get(ax, 'children');
ln = ch(2);
Xdata = get(ln, 'Xdata');
Ydata = get(ln, 'Ydata');
dlmwrite([fname '.txt'], Ydata');
