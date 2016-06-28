function plotSpatialData(mapX, mapY, d)

    surface(mapX, mapY, zeros(size(mapY)), d, 'LineStyle','none');
    grid off
    set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
    set(gca, 'YTickMode', 'auto', 'YTickLabelMode', 'auto')