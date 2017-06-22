function [xtickByCellType] = makeHeatmap(D, cellTypes, geneNames, selection, Ngenes, method)

xtickByCellType = cumsum(NofEach_sorted) - (NofEach_sorted/2) + .5

imagesc(log(D_full))

%axis
ax=gca;
set(ax,'yTickLabel',allGeneNames)
set(ax,'ytick', (1:size(D_full,1)))
set(ax,'xTickLabel',uniqueTypes_sorted)
set(ax,'xtick', xtickByCellType+.5)
set(ax,'xTickLabelRotation',45)
