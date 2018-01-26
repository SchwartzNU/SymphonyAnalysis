function [] = generateCombinationMatrix(D, fileChunk, isBinary)

%fileChunk is number of gene pairs in each file
numGenes = size(D,1);
numCells = size(D,2);

nPairs = nchoosek(numGenes,2);
load('allPairs', 'allPairs');

nFiles = ceil(nPairs / fileChunk);
disp(['Preparing to write data for ' num2str(nPairs) ' gene pairs into ' num2str(nFiles) ' files...']);

z=1;
chunkCounter = 1;
while z<nPairs
    tic;
    zInd = z:z+fileChunk-1;
    if zInd(end) > nPairs
        zInd = z:nPairs;
    end
    disp(['Chunk ' num2str(chunkCounter) ':']);
    L = length(zInd);
    if isBinary
        D_pairs = false(L, numCells);
    else
        D_pairs = zeros(L, numCells);
    end
    
    for i=1:L
        for cellInd = 1:numCells
            if isBinary
                D_pairs(i,cellInd) = D(allPairs(zInd(i), 1), cellInd) & D(allPairs(zInd(i), 2), cellInd);
            else
                D_pairs(i,cellInd) = sqrt(D(allPairs(zInd(i), 1), cellInd) * D(allPairs(zInd(i), 2), cellInd)); %geometric mean
            end
        end
    end
    save(['genePairDataBinary/genePairs_' num2str(chunkCounter)], 'D_pairs', '-v7.3'); 
    toc;
    z = z+fileChunk;
    chunkCounter = chunkCounter+1;
end


