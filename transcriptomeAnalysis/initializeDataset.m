function [cellIDs, eyeVec, xPos, yPos, cellTypes, geneNames, geneCounts, D, D_filter] = initializeDataset(filename, threshold)
 % [cellIDs, eyeVec, xPos, yPos, cellTypes, geneNames, geneCounts, D, D_filter] = initializeDataset('/Users/jillian/Documents/RNASeq_ExprMatrix_171121.txt', 500)

[cellIDs, eyeVec, xPos, yPos, cellTypes, geneNames, geneCounts, D] = readGenomicsData(filename, threshold);
D_filter = filterExpressionMatrix(D, .5, 10, 1);
[D_topGenes, uniqueTypes_sorted, NofEach_sorted, allGeneNames] = fullSelectiveExpressionMatrix(D_filter, cellTypes, geneNames, 10, 'multi-step');

makeHeatmap(D_topGenes, cellTypes, uniqueTypes_sorted, NofEach_sorted, allGeneNames, 10);

end