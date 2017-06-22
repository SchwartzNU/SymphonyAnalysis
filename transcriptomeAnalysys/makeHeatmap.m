function [xtickByCellType] = makeHeatmap(D_full, cellType, uniqueTypes_sorted, NofEach_sorted, allGeneNames, Ngenes)

%Variables
xtickByCellType = cumsum(NofEach_sorted) - (NofEach_sorted/2) + .5
cumsum_NofEach_sorted = cumsum(NofEach_sorted)

%figure
imagesc(log(D_full))

%Axis Setup
ax=gca;
set(ax, 'TickDir','out', 'yTickLabel',allGeneNames, 'ytick',(1:size(D_full,1)), 'xTickLabel',uniqueTypes_sorted, 'xtick',xtickByCellType+.5, 'xTickLabelRotation',45);

%Grid Generation

%Y-axis Grid
for i=1:length(uniqueTypes_sorted)
    rectangle('Position', [0 (Ngenes*i)+.5 length(cellType)+.5 Ngenes])
end

%X-axis Grid
for i=1:(length(uniqueTypes_sorted)-1)
    rectangle('Position', [cumsum_NofEach_sorted(i)+.5 0 NofEach_sorted(i+1) length(allGeneNames)+.5])
end
        
       

