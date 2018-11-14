%% load txt file
[cellIDs, eyeVec, xPos, yPos, cellTypes, geneNames, geneCounts, D] = readGenomicsData('RNASeq_ExprMatrix_181113', 1000);
save('dataSet_11_2018_thres1000gene_209cells');

%% load data

load('dataSet_11_2018_thres1000gene_209cells');
%variables:
% D
% geneNames
% eyeVec
% cellTypes
% cellIDs
% xPos
% yPos
% geneCounts

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

%% apply cell sorting to each variable
D_s = D(:, cellSortIndex);
if exist('D_GOI', 'var'), disp('GOI found'); D_GOI = D_GOI(:, cellSortIndex); end
eyeVec = eyeVec(cellSortIndex);
cellTypes = cellTypes(cellSortIndex);
xPos = xPos(cellSortIndex);
yPos = yPos(cellSortIndex);
geneCounts = geneCounts(cellSortIndex);

if exist('score', 'var'), score = score(cellSortIndex, :); end

%% optimization loop for geneN_target

geneN_target_vec = [10];
C_within_mean = [];
C_between_mean = [];
for g=1:length(geneN_target_vec)
    
    geneN_target = geneN_target_vec(g);
    %%% feature selection by cell type
    z=1;
    x = cell(1, Ntestable);
    y = cell(1, Ntestable);
    
    %geneN_target = 50;
    
    fullGeneInd = [];
    
    for j=1:Ntestable
        j
        curType = uniqueTypes_sorted{j};
        curInd = z:z + NofEach_sorted(j)-1;
        z = z + NofEach_sorted(j);
        
        disp(curType);
        [~, x{j}, y{j}] = featureSelector_byCellType(D_s, curInd, 10, 6.5);
        b = 2.5;
        Ngenes = 0;
        while Ngenes < geneN_target
            geneInd = genesAboveEquation(x{j}, y{j}, 0.65, b);
            Ngenes = length(geneInd);
            b=b-.01;
        end
        geneNames(geneInd)
        pause;
        %disp(['b = ' num2str(b)]);
        fullGeneInd = [fullGeneInd; geneInd];
    end
    
    fullGeneInd_un = unique(fullGeneInd);
    
    %cut matrix to genes of interest
    
    D_GOI = D_s(fullGeneInd_un, :);
    geneNames_GOI = geneNames(fullGeneInd_un);
    N_GOI = length(fullGeneInd_un);
    %disp([num2str(N_GOI) ' genes selected']);
    
    %get log mean expression pattern for each cell type
    
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
    
    %correlation matrices
    %need to add cross validation to this.
    
    C_allCells = corrcoef(D_GOI_log);
    C_typeMeans = corrcoef(typeLogMeans);
    
    Ncells = size(D,2);
    
    C_cellsToTypes = zeros(Ntestable, Ncells);
    
    for i=1:Ncells
        
        tempM = [typeLogMeans, D_GOI_log(:,i)];
        tempC = corrcoef(tempM);
        C_cellsToTypes(:,i) = tempC(1:end-1,end);
    end
    
    %compute corr for each type
    z=1;
    Cmean_byType = zeros(Ntestable,Ntestable);
    
    typeInd = cell(1,Ntestable);
    for i=1:Ntestable
        curType = uniqueTypes_sorted{i};
        curInd = z:z + NofEach_sorted(i)-1;
        typeInd{i} = curInd;
        z = z + NofEach_sorted(i);
    end
    
    for i=1:Ntestable
        for j=1:Ntestable
            pairwiseInd = allIndicesPairwise(typeInd{i}, typeInd{j});
            Cmean_byType(i,j) = mean(mean(C_allCells(pairwiseInd(:,1), pairwiseInd(:,2))));
        end
    end
    
    C_within = Cmean_byType(logical(eye(Ntestable)));
    C_between = Cmean_byType(logical(~eye(Ntestable)));
    C_within_mean(g) = mean(C_within);
    C_between_mean(g) = mean(C_between);    
end

%% plot correlation matrices
figure(1);
C_allCells(C_allCells==1) = nan;
imagesc(C_allCells);
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'x');
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'y');

figure(2);
imagesc(C_cellsToTypes);
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'x');
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'y');

figure(3);
imagesc(Cmean_byType);
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'x');
addCellTypeLabels(uniqueTypes_sorted, NofEach_sorted, 'y');

%% correlation for each Sanes cell with means
CV_thres = 0; %0 for use all genes

%%%% load sanes data
load('SanesData/sanesGeneNames');
dataSets = 'ABCDE';
L = length(dataSets);
maxCorr = {};
maxInd = {};
allC_flat = [];
for dset=1:L
    dset
    curSetName = ['sanes' dataSets(dset)];
    load(['SanesData/' curSetName]);
    eval(['sanesData = sanes' dataSets(dset) '_sparse;']);
    %%% transform sanes data
    [Ngenes_sanes, Ncells_sanes] = size(sanesData);
    %D_sanes_log = log10(sanesData+1);
    D_sanes_log = sanesData;
    D_sanes_log(D_sanes_log<1) = 0; %threshold 10 (before log transform) to 0
    matchingInd = index2SanesIndex(geneNames, sanesGeneNames, fullGeneInd_un);
    matched = matchingInd > 0;
    L = sum(matched);
    disp([num2str(L) ' of ' num2str(N_GOI) ' genes matched: (' num2str(100*L./N_GOI) '%)']);
    matchingInd(matchingInd==0) = nan;
    
    D_sanes_log_GOI = D_sanes_log(matchingInd(matched),:);
    D_GOI_log_matched = D_GOI_log(matched, :);
    typeLogMeans_matched = typeLogMeans(matched, :);

    %%%% get corrcoeff of each cell with all the types
    
    C_sanesCellsToTypes = zeros(Ntestable, Ncells_sanes);
    C_sanesCellsToTypes_norm = zeros(Ntestable, Ncells_sanes);
    
    z=1;
    for j=1:Ntestable
        
        %%get genes ordered by CV (of log) for each cell type
        allCV_matched = zeros(L, Ntestable);
        allGeneOrder_matched = zeros(L, Ntestable);
        
        curType = uniqueTypes_sorted{j};
        curInd = z:z + NofEach_sorted(j)-1;
        z = z + NofEach_sorted(j);
        
        tempCV = std(D_GOI_log_matched(:, curInd), [], 2) ./ mean(D_GOI_log_matched(:, curInd),2);
        %keyboard;
        [allCV_matched(:,j), allGeneOrder_matched(:,j)] = sort(tempCV, 'MissingPlacement', 'first');
        
        if CV_thres > 0
            breakVal = find(allCV_matched(:,j)>CV_thres, 1);
            if ~isempty(breakVal)
                geneUseInd = allGeneOrder_matched(1:breakVal-1, j);
            else
                geneUseInd = 1:L;
            end
        else
            geneUseInd = 1:L;
        end
        Nused = length(geneUseInd);
        disp([uniqueTypes_sorted{j} ': ' num2str(Nused) ' genes selected.']);
        for i=1:Ncells_sanes
            tempC = corrcoef(D_sanes_log_GOI(geneUseInd,i),typeLogMeans_matched(geneUseInd, j));
            C_sanesCellsToTypes(j,i) = tempC(1,2);
        end
    end
    %
    %     for i=1:Ncells_sanes
    %
    %
    % %         tempM = [typeLogMeans_matched, D_sanes_log_GOI(:,i)];
    % %         tempC = corrcoef(tempM);
    % %         C_sanesCellsToTypes(:,i) = tempC(1:end-1,end);
    %     end
    
    allC_flat = [allC_flat; C_sanesCellsToTypes(:)];
    [maxCorr{dset}, maxInd{dset}] = max(C_sanesCellsToTypes, [], 1);
%    [maxCorr_norm{dset}, maxInd_norm{dset}] = max(C_sanesCellsToTypes_norm);
end

%% plot match histograms
allMaxCorr = cell2mat(maxCorr);
allMaxCorr = reshape(allMaxCorr, [1, numel(allMaxCorr)]);
allMaxInd = cell2mat(maxInd);
allMaxInd = reshape(allMaxInd, [1, numel(allMaxInd)]);

mean_allCorr_m = mean(allC_flat);

bestMatchCutoff = 1; %s.d.
ind = allMaxCorr>mean_allCorr_m + bestMatchCutoff * std(allC_flat);
disp([num2str(sum(ind)) ' of ' num2str(length(allMaxCorr)) ' (' ...
    num2str(100*sum(ind)/length(allMaxCorr)) '%) matched exceeded threshold: ' ...
    num2str(bestMatchCutoff) ' s.d.']);
bestMatchCorr = allMaxCorr(ind);
bestMatchInd = allMaxInd(ind);

Nmatches = histcounts(bestMatchInd,1:Ntypes+1);
bar(1:Ntypes, Nmatches);
ax = gca;
set(ax, 'xtick', 1:Ntypes);
set(ax, 'xticklabels', uniqueTypes_sorted);
set(ax, 'xTickLabelRotation', 90);
ylabel('Number of matches');




