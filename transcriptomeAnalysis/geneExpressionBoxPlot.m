function [uniqueTypes, allExpression, allCategories, allLabels] = geneExpressionBoxPlot(D, cellTypes, geneNames, gene, directionPref)

if ~isempty(directionPref)
    for i=1:length(cellTypes)
        if ~strcmp(directionPref{i}, '-')
            cellTypes{i} = [cellTypes{i} ':' directionPref{i}];
        end
    end
end


% gene should be a unique cell name!
geneInd = find(strcmp(geneNames, gene));
allExpression = [];
allCategories = [];
allLabels = [];

uniqueTypes = unique(cellTypes);

for i=1:length(uniqueTypes)
    currentType = uniqueTypes{i};
    currentTypeInd = find(contains(cellTypes, currentType)); 
    
    currentTypeExpression = D(geneInd,currentTypeInd);
    disp([currentTypeExpression]);
    currentTypeCategories = zeros(1,length(currentTypeInd))+i;
    
    allExpression = cat(2, allExpression, currentTypeExpression);
    allCategories = cat(2, allCategories, currentTypeCategories);
    
    allLabels = cat(2, [allLabels, string(currentType)]);
end

figure;
notBoxPlot(allExpression,allCategories);
xticklabels({allLabels});
xtickangle(60);
title(string(gene)+" Expression by Cell Type");
ylabel("Normalized Gene Expression");
end