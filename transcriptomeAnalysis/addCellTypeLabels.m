function [] = addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, whichAxis)

%Variables
tickByCellType = cumsum(NofEach_sorted) - (NofEach_sorted/2) + .5;
cumsum_NofEach_sorted = cumsum(NofEach_sorted);

%Axis Setup
ax=gca;
xrange = get(ax, 'xlim');
yrange = get(ax, 'ylim');

if strcmp(whichAxis, 'x')
    set(ax, 'TickDir','out',...
        'xTickLabel',uniqueTypes_sorted,...
        'TickLabelInterpreter', 'none',...
        'xTickLabelRotation',45);
    
    if range(xrange) <= length(uniqueTypes_sorted) % one tick for each
        set(ax, 'xtick',1:length(uniqueTypes_sorted)-0.5);
    else %ticks for each group of cells
        set(ax, 'xtick',tickByCellType);
        
        %Vertical Grid
        for i=1:(length(uniqueTypes_sorted)-1)
            rectangle('Position', [cumsum_NofEach_sorted(i)+.5 yrange(1) NofEach_sorted(i+1) yrange(2)])
        end
    end
else
    set(ax, 'TickDir','out',...
        'yTickLabel',uniqueTypes_sorted,...
        'TickLabelInterpreter', 'none',...
        'yTickLabelRotation',0);
    
    if range(yrange) <= length(uniqueTypes_sorted) % one tick for each
        set(ax, 'ytick',1:length(uniqueTypes_sorted)-0.5);
    else
        set(ax, 'ytick',tickByCellType);
        
        %Horizontal Grid
        for i=1:(length(uniqueTypes_sorted)-1)
            rectangle('Position', [xrange(1) cumsum_NofEach_sorted(i)+.5 xrange(2) NofEach_sorted(i+1)]);
        end
    end
end