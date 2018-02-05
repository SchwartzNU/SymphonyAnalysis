%function [] = generateCombinationMatrix_par(D, fileChunk, isBinary)
%_par is parallel version

%path
addpath('code/transcriptomeAnalysis/');
addpath('code/');

%load data
load('data/transcriptomicsData_01_2018.mat');
load('data/allPairs', 'allPairs');
%loads allPairs, D

%load params
params = dlmread('params/noBinary_chunk1M');
fileChunk = params(1);
isBinary = params(2);

numGenes = size(D,1);
numCells = size(D,2);

nPairs = nchoosek(numGenes,2);

nFiles = ceil(nPairs / fileChunk);
disp(['Preparing to write data for ' num2str(nPairs) ' gene pairs into ' num2str(nFiles) ' files...']);

if isBinary
    folderName = 'genePairDataBinary';
else
    folderName = 'genePairDataGMean';
end

parpool('local', 20);

nChunks = ceil(nPairs/fileChunk);

parfor chunkCounter=1:nChunks
    tic;
    zInd = (chunkCounter-1)*fileChunk+1:chunkCounter*fileChunk
    if zInd(end) > nPairs        
        zInd = (chunkCounter-1)*fileChunk+1:nPairs;
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
    [folderName filesep 'genePairs_' num2str(chunkCounter)]
    saveDataFile_v73([folderName filesep 'genePairs_' num2str(chunkCounter)], D_pairs, 'D_pairs'); 
    toc;
end


