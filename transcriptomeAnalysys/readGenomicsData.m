function [cellIDs, eyeVec, xPos, yPos, cellType, directionPref, geneNames, geneCounts, D] = readGenomicsData(filename, geneCountThreshold)
A = readtable(filename, 'ReadVariableNames', false, 'Delimiter', '\t');
cellIDs = A{2,2:end};
% eyeVec = A{2,2:end};
% xPos = A{3,2:end};
% yPos = A{4,2:end};
% cellType = A{5,2:end};

directionPref = A{5,2:end};
cellType = A{10,2:end};
eyeVec = A{9,2:end};
xPos = A{7,2:end};
yPos = A{8,2:end};


geneNames = A{11:end,1};
D = str2double(A{11:end,2:end});
D_thres = D>0;

geneCounts = sum(D_thres,1);

goodInd = find(geneCounts > geneCountThreshold);
disp([num2str(length(goodInd)) ' of ' num2str(length(geneCounts)) ' cells passed threshold of ' num2str(geneCountThreshold) ' genes.']);

cellIDs = cellIDs(goodInd);
eyeVec = eyeVec(goodInd);
xPos = xPos(goodInd);
yPos = yPos(goodInd);
cellType = cellType(goodInd);
D = D(:, goodInd);
geneCounts = geneCounts(goodInd);



