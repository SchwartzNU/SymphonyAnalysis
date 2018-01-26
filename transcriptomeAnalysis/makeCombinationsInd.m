%makeCombinationsInd(D)

numGenes = size(D,1);
nPairs = nchoosek(numGenes,2);
allPairs = zeros(nPairs,2);

z=1;
for i=1:numGenes
    %i
    %tic;
    for j=i+1:numGenes
        allPairs(z,:) = [i, j];
        z=z+1;
    end 
    %toc;
end

save('genePairData/allPairs', 'allPairs');
