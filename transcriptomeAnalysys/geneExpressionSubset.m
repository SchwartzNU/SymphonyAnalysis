function [targetInd, geneInd, geneCounts] = geneExpressionSubset(D, cellTypes, geneNames, gene, selection, makeGraph)

if ischar(selection)
    selectedType = selection;
    targetInd = find(contains(cellTypes, selectedType));
    disp([num2str(length(targetInd)) ' cells of type ' selectedType ', including:']);
    disp([unique(cellTypes(targetInd))]);
else
    targetInd = selection;
    disp([num2str(length(targetInd)) ' cells selected.']);
end

geneInd = find(contains(geneNames, gene)); 

disp([num2str(length(geneInd)) ' genes containing ' gene ', including:']);
disp([geneNames(geneInd)]);

geneCounts = D(geneInd,targetInd);

if makeGraph == 1;
    figure;
    imagesc(log(geneCounts))

    %Axis Setup
    ax=gca;
    set(ax, 'TickDir','out',...
        'yTickLabel',geneNames(geneInd),...
        'ytick',(1:size(geneCounts,1)),...
        'xTickLabel',targetInd,...
        'xtick',[1:length(targetInd)],...
        'xTickLabelRotation',45);
else
end

end