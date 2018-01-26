function nameStr = geneNamesFromPairIndex(allPairs, geneNames, ind)
gene1 = geneNames{allPairs(ind,1)};
gene2 = geneNames{allPairs(ind,2)};

nameStr = [gene1 ', ' gene2];

