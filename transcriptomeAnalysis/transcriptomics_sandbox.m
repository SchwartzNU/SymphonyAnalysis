%% Sanes data conversion
sanesE = load('TPMe.txt');
sanesE_sparse = spconvert(sanesE(2:end,:));

%% load data

load('dataSet_10_2018_thres1000gene_243cells');
%variables:
% D
% geneNames
% eyeVec
% cellTypes
% cellIDs
% xPos
% yPos
% geneCounts

%% feature selection

geneInd = featureSelector(D, 0.5, 6.0);
N_GOI = length(geneInd);
disp([num2str(N_GOI) ' genes selected.']);

%% cut matrix to genes of interest

D_GOI = D(geneInd, :);

geneNames_GOI = geneNames(geneInd);

%% PCA

[coeff,score,latent] = pca(D_GOI');
fractionVar = latent./sum(latent);
cutoff = 6; %inspected graph
disp(['First ' num2str(cutoff) ' components explain ' num2str(100*sum(fractionVar(1:cutoff))) '% of the variance.']);
score = score(:,1:cutoff);

%% Sort by cell type
uniqueTypes = unique(cellTypes);

Ntypes = length(uniqueTypes);
NofEach = zeros(1,Ntypes);
%sort by most prevalent
for i=1:Ntypes
    NofEach(i) = length(find(strcmp(uniqueTypes{i}, cellTypes)));
end
[NofEach_sorted, ind] = sort(NofEach, 'descend');
uniqueTypes_sorted = uniqueTypes(ind);

Ntestable = length(find(NofEach>2));
%sort by type
ind = [];
for i=1:Ntypes
    ind = [ind, find(strcmp(uniqueTypes_sorted{i}, cellTypes))];
end
cellSortIndex = ind;

%% apply sorting to each variable
D_s = D(:, cellSortIndex);
D_GOI = D_GOI(:, cellSortIndex);
eyeVec = eyeVec(cellSortIndex);
cellTypes = cellTypes(cellSortIndex);
xPos = xPos(cellSortIndex);
yPos = yPos(cellSortIndex);
geneCounts = geneCounts(cellSortIndex);

%score = score(cellSortIndex, :);

%% get log mean expression pattern for each cell type

D_GOI_log = log10(D_GOI+1);
typeLogMeans = zeros(N_GOI, Ntestable);

z=1;
for i=1:Ntypes
    if NofEach_sorted(i) > 2
        curType = uniqueTypes_sorted{i};
        curInd = z:z + NofEach_sorted(i)-1;
        L = length(curInd);
        z = z + NofEach_sorted(i);
        
        typeLogMeans(:,i) = mean(D_GOI_log(:, curInd),2);
        
    end
end

%% correlation matrices

C_allCells = corrcoef(D_GOI_log);
C_typeMeans = corrcoef(typeLogMeans);

Ncells = size(D,2);

C_cellsToTypes = zeros(Ntestable, Ncells);

for i=1:Ncells
    tempM = [typeLogMeans, D_GOI_log(:,i)];
    tempC = corrcoef(tempM);
    C_cellsToTypes(:,i) = tempC(1:end-1,end);
end

%% plot correlation matrices
figure(1);
imagesc(C_allCells);
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'x');
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'y');

figure(2);
imagesc(C_cellsToTypes);
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'x');
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'y');

%% correlation for each Sanes cell with means

%%%% load sanes data
load('SanesData/sanesGeneNames');
dataSets = 'ABCDE';
L = length(dataSets);
maxCorr = {};
maxInd = {};
for z=1:L
    z
    curSetName = ['sanes' dataSets(z)];
    load(['SanesData/' curSetName]);
    eval(['sanesData = sanes' dataSets(z) '_sparse;']);
    %%% transform sanes data
    [Ngenes_sanes, Ncells_sanes] = size(sanesData);
    D_sanes_log = log10(sanesData+1);
    matchingInd = index2SanesIndex(geneNames, sanesGeneNames, geneInd);
    matched = matchingInd > 0;
    L = sum(matched);
    disp([num2str(L) ' of ' num2str(N_GOI) ' genes matched: (' num2str(100*L./N_GOI) '%)']);
    matchingInd(matchingInd==0) = nan;
    
    D_sanes_log_GOI = D_sanes_log(matchingInd(matched),:);
    D_GOI_log_matched = D_GOI_log(matched, :);
    typeLogMeans_matched = typeLogMeans(matched, :);
    
    %%%% get corrcoeff of each cell with all the types
    
    C_sanesCellsToTypes = zeros(Ntestable, Ncells_sanes);
    for i=1:Ncells_sanes
        tempM = [typeLogMeans_matched, D_sanes_log_GOI(:,i)];
        tempC = corrcoef(tempM);
        C_sanesCellsToTypes(:,i) = tempC(1:end-1,end);
    end
    
    [maxCorr{z}, maxInd{z}] = max(C_sanesCellsToTypes);
end

%% plot match histograms
allMaxCorr = cell2mat(maxCorr);
allMaxCorr = reshape(allMaxCorr, [1, numel(allMaxCorr)]);
allMaxInd = cell2mat(maxInd);
allMaxInd = reshape(allMaxInd, [1, numel(allMaxInd)]);

Nmatches = histcounts(allMaxInd,1:Ntypes+1);
bar(1:Ntypes, Nmatches);
ax = gca;
set(ax, 'xtick', 1:Ntypes);
set(ax, 'xticklabels', uniqueTypes_sorted);
set(ax, 'xTickLabelRotation', 90);
ylabel('Number of matches');

%% look at PCs for each cell type

z = 1;
for i=1:Ntypes
    if NofEach_sorted(i) > 2
        curType = uniqueTypes_sorted{i};
        curInd = z:z + NofEach_sorted(i)-1;
        L = length(curInd);
        z = z + NofEach_sorted(i);
        %find(strcmp(curType, cellTypes))
        
        scoreMeans = mean(score(curInd,:), 1);
        scoreSEM = std(score(curInd,:), [], 1)./sqrt(L);
        
        figure(i);
        errorbar(1:cutoff, scoreMeans, scoreSEM, 'bx');
        title([curType ': N = ' num2str(L)]);
        
        pause;
        %         figure(i);
        %
        %
        %         [~, ~, ~, curD, ~, geneNames_sorted] = ...
        %             selectiveExpressionMatrix(D_sorted, cellTypes, geneNames, uniqueTypes_sorted{i}, Ngenes, method);
        %         D_topGenes(curInd:curInd+Ngenes-1,:) = curD;
        %         allGeneNames = [allGeneNames; geneNames_sorted];
        %         curInd = curInd+Ngenes;
    end
end

%% clustering
meanDist = zeros(1,59);
for i=2:60
    [idx,centroids,sumd,distMatrix] = kmeans(score, i);
    meanDist(i-1) = mean(sumd);
end



