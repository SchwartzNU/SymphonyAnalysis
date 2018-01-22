function [cellIDs, eyeVec, xPos, yPos, cellTypes, geneNames, geneCounts, D] = readGenomicsData(filename, geneCountThreshold)
A = readtable(filename, 'ReadVariableNames', false, 'Delimiter', '\t');
cellIDs = A{2,2:end};

xPos = A{4,2:end};
yPos = A{5,2:end};
eyeVec = A{6,2:end};
cellTypes = A{7,2:end};
geneNames = A{8:end,1};
D = str2double(A{8:end,2:end});
D_thres = D>0;

geneCounts = sum(D_thres,1);

goodInd = find(geneCounts > geneCountThreshold);
disp([num2str(length(goodInd)) ' of ' num2str(length(geneCounts)) ' cells passed threshold of ' num2str(geneCountThreshold) ' genes.']);

cellIDs = cellIDs(goodInd);
eyeVec = eyeVec(goodInd);
xPos = xPos(goodInd);
yPos = yPos(goodInd);
cellTypes = cellTypes(goodInd);
D = D(:, goodInd);
geneCounts = geneCounts(goodInd);



