function [cellIDs, eyeVec, xPos, yPos, cellTypes, subtype, directionPref, geneNames, geneCounts, D, D_filter] = initializeDataset(filename, threshold)
 % [cellIDs, eyeVec, xPos, yPos, cellTypes, subtype, directionPref, geneNames, geneCounts, D, D_filter] = initializeDataset('/Users/jillian/Documents/RNASeq_ExprMatrix_171011_withoutHD1double.txt', 500)
[cellIDs, eyeVec, xPos, yPos, cellTypes, subtype, directionPref, geneNames, geneCounts, D] = readGenomicsData(filename, threshold);
D_filter = filterExpressionMatrix(D, .5, 10, 1);
[D_topGenes, uniqueTypes_sorted, NofEach_sorted, allGeneNames, targetInd_all] = fullSelectiveExpressionMatrix(D_filter, cellTypes, geneNames, 10, 'multi-step', directionPref);

makeHeatmap(D_topGenes, cellTypes, uniqueTypes_sorted, NofEach_sorted, allGeneNames, 10, targetInd_all);

end