function [Vgreen, Vuv] = colorIsoGradientVec(ax)
    ch = get(ax, 'Children');
    cIsoMap = get(ch(end), 'CData');
    spacing = 2 / (size(cIsoMap,1) - 1); %-1 to 1 contrast in 20 bins
    
    [px, py] = gradient(cIsoMap,spacing,spacing);
    px = px(2:end-1, 2:end-1);
    py = py(2:end-1, 2:end-1);

    Vgreen = mean(px(:));
    Vuv = mean(py(:));
    disp(['Vgreen: ' num2str(Vgreen) ' Vuv: ' num2str(Vuv)]);
end

