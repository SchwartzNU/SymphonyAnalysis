function [xtickByCellType] = makeHeatmap(D_topGenes, cellType, uniqueTypes_sorted, NofEach_sorted, allGeneNames, Ngenes)


%Variables
xtickByCellType = cumsum(NofEach_sorted) - (NofEach_sorted/2) + .5;
cumsum_NofEach_sorted = cumsum(NofEach_sorted);

figure
imagesc(D_topGenes)

%Axis Setup
ax=gca;
set(ax, 'TickDir','out',...
    'yTickLabel',allGeneNames,...
    'ytick',(1:size(D_topGenes,1)),...
    'xTickLabel',uniqueTypes_sorted,...
    'TickLabelInterpreter', 'none',...
    'xtick',xtickByCellType,...
    'xTickLabelRotation',45);

%Add a top axis for indices if targetInd_all is passed
%if ~isempty(targetInd_all)
%    ax_pos = ax.Position;
%    ax2 = axes('Position',ax_pos,... 
%    'XAxisLocation','top',... 
%    'Color','none',...
%    'xTickLabel',targetInd_all,...
%    'xTickLabelRotation',90);
%end

%Grid Generation

%Horizontal Grid
for i=1:length(uniqueTypes_sorted)
    rectangle('Position', [0 (Ngenes*i)+.5 length(cellType)+.5 Ngenes])
end

%Vertical Grid
for i=1:(length(uniqueTypes_sorted)-1)
    rectangle('Position', [cumsum_NofEach_sorted(i)+.5 0 NofEach_sorted(i+1) length(allGeneNames)+.5])
end
        
       

