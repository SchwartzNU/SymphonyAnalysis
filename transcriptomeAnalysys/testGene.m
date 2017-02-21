function [targetCounts, othersCounts, targetInd, othersInd] = testGene(D, geneNames, cellTypes, targetGene, selectedType)
targetInd = find(strcmp(selectedType, cellTypes));
disp([num2str(length(targetInd)) ' cells of type: ' selectedType]);
othersInd = setdiff(1:length(cellTypes), targetInd);

geneInd = find(strcmp(targetGene, geneNames));
targetCounts = D(geneInd, targetInd);
othersCounts = D(geneInd, othersInd);
