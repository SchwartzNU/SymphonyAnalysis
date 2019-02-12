function [behrensGOI, behrensGOI_index, D_filter_noAllZeros, geneNames_noAllZeros, behrens_D, behrens_geneNames] = behrensFilter(D_filter, geneNames, minExpressionLevel, minPresentCalls, maxPresentCalls) 
% Uses Behrens' technique to first filter the expression matrix by genes
%   with expression levels that include at least one nonzero cell.
% Maps the proportion of expression of those genes against the expression 
%   level of nonzero expression instances.
% Goal is to determine genes with relatively rare, but high expression.

numCells = length(D_filter(1,:));
maxNumberOfZeros = numCells - minPresentCalls;
minNumberOfZeros = numCells - maxPresentCalls;
numZeros = sum((D_filter==0),2);

geneNames_noAllZeros = geneNames(numZeros <= maxNumberOfZeros & numZeros >= minNumberOfZeros);
D_filter_noAllZeros  = D_filter( numZeros <= maxNumberOfZeros & numZeros >= minNumberOfZeros,:);
numZeros_noAllZeros  = numZeros( numZeros <= maxNumberOfZeros & numZeros >= minNumberOfZeros);
fracZeros_noAllZeros = numZeros_noAllZeros/246;

nGenes = length(geneNames_noAllZeros);

% Take average of all nonzero entries for each gene
meanExpr_noAllZeros  = zeros(nGenes,1);

for iter = 1:nGenes
    meanExpr_noAllZeros(iter) = mean(D_filter_noAllZeros(iter,(D_filter_noAllZeros(iter,:)~=0)));
end

figure;
scatter(meanExpr_noAllZeros,fracZeros_noAllZeros);
xlabel('Log_1_0 Expression');
ylabel('Fraction Zeros');

GOIiter = 1;
behrensGOI = {};
behrensGOI_index = [];

for iter = 1:nGenes
    if meanExpr_noAllZeros(iter) > minExpressionLevel
        behrensGOI(GOIiter) = geneNames_noAllZeros(iter);
        behrensGOI_index(GOIiter) = iter;
        GOIiter = GOIiter+1;
    end
end

behrens_D = D_filter_noAllZeros(behrensGOI_index,:);
behrens_geneNames = geneNames_noAllZeros(behrensGOI_index);

figure
imagesc(behrens_D);


end