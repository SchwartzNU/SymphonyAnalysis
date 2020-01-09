%% load txt file
[cellIDs, eyeVec, xPos, yPos, cellTypes, geneNames, geneCounts, D] = readGenomicsData('RNASeq_ExprMatrix_190614.txt', 1000);
save('dataSet_11_2018_thres1000gene_209cells');

%% load data

load('dataSet_06_2019_thres1000gene_247cells');
%load('SchwartzSanesConcatenation')
%variables:
%% concatenated data
D = 10.^int_D;
D(D<10) = 0;
geneNames = int_geneNames;
eyeVec = [G_eyeVec S_eyeVec];
cellTypes = int_cellTypes;
cellIDs = [G_cellIDs S_cellIDs];
xPos = int_xPos;
yPos = int_yPos;
geneCounts = int_geneCounts;

%% SmartSeq data

D = 10.^S_D;
geneNames = S_geneNames;
eyeVec = S_eyeVec;
cellTypes = S_cellTypes;
cellIDs = S_cellIDs;
xPos = S_xPos;
yPos = S_yPos;
geneCounts = S_geneCounts;

%% Jillian method data

D = G_D;
D_filter = F_D_filter;
geneNames = G_geneNames;
eyeVec = G_eyeVec;
cellTypes = G_cellTypes;
cellIDs = G_cellIDs;
xPos = G_xPos;
yPos = G_yPos;
geneCounts = G_geneCounts;


%% load full Sanes data set 
load('SanesData/sanesGeneNames');
dataSets = 'ABCDE';
L = length(dataSets);
F = [];

for dset=1:L
    dset
    curSetName = ['sanes' dataSets(dset)];
    load(['SanesData/' curSetName]);
    eval(['sanesData = sanes' dataSets(dset) '_sparse;']);
    F = [F, sanesData];
end


%% find differentially expressed genes in Sanes data
minThres = 1; % log scale

[Ngenes, Ncells] = size(F);
temp = (F<minThres & F>0);
numLows = sum(temp(:));
nonZeros = sum(sum(F>0));
disp([num2str(numLows) ' low expression entries set to zero: ' num2str(100*numLows./nonZeros) '% of nonzeros.']);
F(temp) = 0;

isPresent = F>0;
fracPresent = mean(isPresent,2);

meanLogNonZeroExpression = zeros(Ngenes, 1);
for i=1:Ngenes
    if rem(i,100) == 0
        i
    end
    meanLogNonZeroExpression(i) = sum(F(i,:)) ./ nnz(F(i,:));
end

size(meanLogNonZeroExpression)

geneInd = [];
[geneInd, x, y] = genesAboveEquation(meanLogNonZeroExpression, 1-fracPresent, 4, 1.5, 0, (Ncells-50) / Ncellls);
figure(1);
scatter(meanLogNonZeroExpression, 1-fracPresent, 'bx');
%hold on;
%plot(x, y, 'r');
%set(gca,'ylim',[0, 1]);
%hold off;

%% kmeans test
kVec = 30:60;
L = length(kVec);

labelVec = cell(1,L);
fitErrs = cell(1,L);
meanErr = zeros(1,L);
medErr = zeros(1,L);

for i=1:L
    disp(['k = ' num2str(kVec(i)) '. ' num2str(i) ' of ' num2str(L)]);
    [labelVec{i}, ~, fitErrs{i}] = kmeans(full(sanesDataFull'), kVec(i), 'MaxIter', 1000000, 'Distance', 'cosine', 'replicates', 20);
    meanErr(i) = mean(fitErrs{i})
    medErr(i) = median(fitErrs{i})
end

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
cellIDS = cellIDs(cellSortIndex);

if exist('score', 'var'), score = score(cellSortIndex, :); end

%% load Sanes label data

fid = fopen('SanesData/rgc10x_labels.txt');
temp = textscan(fid, '%s', 'Delimiter', ' ');
temp = temp{1};
[~,labels] = strtok(temp);
labels = deblank(labels);
L = length(labels);
labelIDs = zeros(L,1);
labelNames = cell(L,1);
for i=1:length(labels)
    [a, b]  = strtok(labels{i}, '_');
%     if strcmp(a(end), 'N')
%         labelIDs(i) = str2double(a(2:end-1));
%         labelNames{i} = [a(2:end-1) '_' b(2:end)];
%     else
        labelIDs(i) = str2double(a(2:end));
        labelNames{i} = [a(2:end) '_' b(2:end)];
%     end
end

[unique_labelIDs, ind] = unique(labelIDs);
unique_names = labelNames(ind);

%% load new cluster labels
load('SanesData/newClustNumbers'); 
labelIDs = idx;
labelNames = num2str(idx, '%d\n');

unique_labelIDs = unique(labelIDs);
unique_names = unique(labelNames, 'rows');



%% optimization loop for geneN_target

doSanesMatch = false;

%geneN_target_vec = [10];
geneN_target_vec = [10];
C_within_mean = [];
C_between_mean = [];
meanHighestFracPercent = [];

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
        Ncells = sum(NofEach_sorted);
        while Ngenes < geneN_target
            geneInd = genesAboveEquation(x{j}, y{j}, 0.65, b, 2/Ncells, (Ncells-1) / Ncells);
            Ngenes = length(geneInd);
            b=b-.01;
        end
        geneNames(geneInd)
        %pause;
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
    typeLogMeans_CV = cell(Ntestable); %cross-validated
    
    z=1;
    for i=1:Ntypes
        if NofEach_sorted(i) > 2
            curType = uniqueTypes_sorted{i};
            curInd = z:z + NofEach_sorted(i)-1;
            L = length(curInd);
            z = z + NofEach_sorted(i);
            
            typeLogMeans(:,i) = mean(D_GOI_log(:, curInd),2);
            
            for j=1:NofEach_sorted(i)   
                tempInd = setdiff(curInd, curInd(j));
                typeLogMeans_CV{i}(:, j) = mean(D_GOI_log(:, tempInd),2);
            end
        end
    end
    
    %correlation matrices
    %in the middel of adding cross validation to this.
    
    C_allCells = corrcoef(D_GOI_log);
    C_typeMeans = corrcoef(typeLogMeans);
    
    Ncells = size(D,2);
    
    C_cellsToTypes = zeros(Ntestable, Ncells);
        
    for i=1:Ncells
        
        tempM = [typeLogMeans, D_GOI_log(:,i)];
        tempC = corrcoef(tempM);
        C_cellsToTypes(:,i) = tempC(1:end-1,end);
    end
    
    cum_cellCount = [1 cumsum(NofEach_sorted)+1];    
    for i=1:Ncells        
        type_ind = find(cum_cellCount > i, 1)-1;
        if type_ind<=Ntestable
            cell_in_type_ind = i-cum_cellCount(type_ind)+1;
            tempM = [typeLogMeans_CV{type_ind}(:,cell_in_type_ind), D_GOI_log(:,i)];
            tempC = corrcoef(tempM);
            %overwrite just this entry with cross-validated data
            C_cellsToTypes(type_ind,i) = tempC(1:end-1,end);
        end
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
    
    CV_thres = 0; %0 for use all genes
    
    sanesDataFull = []
    
    if doSanesMatch
        %%%% load sanes data and test it
        load('SanesData/sanesGeneNames');
        dataSets = 'ABCDE';
        L = length(dataSets);
        maxCorr = {};
        maxInd = {};
        allC_flat = [];
        allC_full = [];
        for dset=1:L
            dset
            curSetName = ['sanes' dataSets(dset)];
            load(['SanesData/' curSetName]);
            eval(['sanesData = sanes_' dataSets(dset) '_sparse;']);
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
            
            sanesDataFull = [sanesDataFull, D_sanes_log_GOI];
            
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
            
            allC_full = [allC_full C_sanesCellsToTypes];
            allC_flat = [allC_flat; C_sanesCellsToTypes(:)];
            [maxCorr{dset}, maxInd{dset}] = max(C_sanesCellsToTypes, [], 1);
            %    [maxCorr_norm{dset}, maxInd_norm{dset}] = max(C_sanesCellsToTypes_norm);
        end
        
        %%% match statistics
        [Ntypes, Ncells_sanes] = size(allC_full);
        
        marginals = zeros(Ncells_sanes, 1);
        for i=1:Ncells_sanes
            marginals(i) = max(allC_full(:,i)) - prctile(allC_full(:,i), 80);
        end
        
        bestMatchCutoff = 2; %s.d.
        matchingCells = cell(Ntypes, 1);
        matchingLabels = cell(Ntypes, 1);
        highestFracClust = zeros(Ntypes, 1);
        highestFracPercent = zeros(Ntypes, 1);
        pieCharts = cell(Ntypes, 1);
        
        for i=1:Ntypes
            curC = allC_full(i,:);
            thres = mean(curC) + bestMatchCutoff * std(curC);
            ind = find(curC>thres);
            matchingCells{i} = ind;
            matchingLabels{i} = labelIDs(ind);
            [highestFracClust(i), temp] = mode(matchingLabels{i});
            highestFracPercent(i) = 100*temp / length(ind);
            disp([uniqueTypes_sorted{i} ': ' num2str(length(ind)) ' matches']);
            disp(['Best matching cluster: ' num2str(highestFracClust(i)) ' (' num2str(highestFracPercent(i)) '%)']);
            
            allClust = unique(matchingLabels{i});
            Nclust = length(allClust);
            curPie = zeros(Nclust, 2);
            curPie(:,1) = allClust;
            for j=1:Nclust
                curPie(j,2) = length(find(matchingLabels{i}==allClust(j))) ./ length(ind);
            end
            pieCharts{i} = curPie;
            figure(1);
            scatter(curPie(:,1), curPie(:,2));
            pause;
        end
        
        meanHighestFracPercent(g) = mean(highestFracPercent);
    end
end

%% dendrogram
Z = linkage(typeLogMeans');
labels = uniqueTypes_sorted(1:30);
dendrogram(Z)

%dendrogram(Z, 'labels', labels, 'orientation', 'left')
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
allC_full = [];
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
    
    allC_full = [allC_full C_sanesCellsToTypes];
    allC_flat = [allC_flat; C_sanesCellsToTypes(:)];
    [maxCorr{dset}, maxInd{dset}] = max(C_sanesCellsToTypes, [], 1);
    %    [maxCorr_norm{dset}, maxInd_norm{dset}] = max(C_sanesCellsToTypes_norm);
end

%% match statistics
[Ntypes, Ncells_sanes] = size(allC_full);

marginals = zeros(Ncells_sanes, 1);
for i=1:Ncells_sanes
    marginals(i) = max(allC_full(:,i)) - prctile(allC_full(:,i), 80);
end

bestMatchCutoff = 2; %s.d.
percentile_cutoff = 99;
matchingCells = cell(Ntypes, 1);
matchingLabels = cell(Ntypes, 1);
highestFracClust = zeros(Ntypes, 1);
highestFracPercent = zeros(Ntypes, 1);
pieCharts = cell(Ntypes, 1);

for i=1:Ntypes
    curC = allC_full(i,:);
    thres = mean(curC) + bestMatchCutoff * std(curC);
    %thres = prctile(curC, percentile_cutoff);
    ind = find(curC>thres);
    matchingCells{i} = ind;
    matchingLabels{i} = labelIDs(ind);
    [highestFracClust(i), temp] = mode(matchingLabels{i});
    highestFracPercent(i) = 100*temp / length(ind);
    disp([uniqueTypes_sorted{i} ': ' num2str(length(ind)) ' matches']);
    disp(['Best matching cluster: ' num2str(highestFracClust(i)) ' (' num2str(highestFracPercent(i)) '%)']);
    
    allClust = unique(matchingLabels{i});
    Nclust = length(allClust);
    curPie = zeros(Nclust, 2);
    curPie(:,1) = allClust;
    for j=1:Nclust
        curPie(j,2) = length(find(matchingLabels{i}==allClust(j))) ./ length(ind);
    end
    pieCharts{i} = curPie;
    figure(1);
    scatter(curPie(:,1), curPie(:,2));
    pause;
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


%% export pie charts
for i=1:length(pieCharts)
    curType = uniqueTypes_sorted{i};
    curPie = pieCharts{i};
    temp = zeros(45,1);
    temp(curPie(:,1)) = curPie(:,2);
    dlmwrite(['pie_' curType '.txt'], temp);
end

%% make typeIndex classifier row
L = sum(NofEach_sorted);
cellTypeIndexVec = zeros(1,L);

z=1;
for i=1:length(NofEach_sorted)
    cellTypeIndexVec(z:z+NofEach_sorted(i)-1) = i;
    z=z+NofEach_sorted(i);
end

%add it to D matrix for RF algorithm
RF_input = [D_GOI_log; cellTypeIndexVec];

%% Cut last cell (singleton)
D_GOI_log_matched_29Type = D_GOI_log_matched(:,1:end-1);
cellTypes_29 = cellTypes(1:end-1);
uniqueTypes_sorted_29 = uniqueTypes_sorted(1:end-1);

%% train classifier 
%[trainedClassifier, validationAccuracy] = trainClassifier(D_GOI_log_matched, cellTypes, uniqueTypes_sorted);
[trainedClassifier, validationAccuracy] = trainClassifier(D_GOI_log_matched_29Type, cellTypes_29, uniqueTypes_sorted_29);


%% predict using classifier

[idx, scoreMatrix] = trainedClassifier.predictFcn(D_GOI_log_matched_29Type);
[idx_sanes, scoreMatrix_sanes] = trainedClassifier.predictFcn(sanesDataFull);

%% make indexVec for classifier output
L = length(idx_sanes);
idVec_sanes = zeros(1,L);

for i=1:L
   idVec_sanes(i) = strmatch(idx_sanes{i}, uniqueTypes_sorted_29, 'exact');
end

L = length(idx);
idVec = zeros(1,L);

for i=1:L
   idVec(i) = strmatch(idx{i}, uniqueTypes_sorted, 'exact');
end


%% label IDs for sanes data

uniqueIDs = unique(idVec);
L = length(uniqueIDs);


sd_thres = -1; %-1 = weighted by s.d.

NsanesLabels = length(unique_labelIDs)
sanesLabelN = histcounts(labelIDs,1:NsanesLabels+1);
Nmatches = [];

for i=1:L
   selectedInd = idVec_sanes==uniqueIDs(i);
   curIDs = labelIDs(selectedInd);
   curScores = scoreMatrix_sanes(selectedInd, uniqueIDs(i));
   curScores_norm = curScores ./ std(curScores);
   
   if sd_thres > 0
       highScoreInd = curScores > mean(curScores) + sd_thres * std(curScores);
       Nmatches = histcounts(curIDs(highScoreInd),1:NsanesLabels+1);
   elseif sd_thres == -1
      for j=1:NsanesLabels
          ind = find(curIDs == j);          
          Nmatches(j) = sum(curScores_norm(ind));
      end
   else
      Nmatches = histcounts(curIDs,1:NsanesLabels+1);      
   end
   bar(1:NsanesLabels, Nmatches);
   %bar(1:NsanesLabels, Nmatches./sanesLabelN);
   ax = gca;
   title([uniqueTypes_sorted{i} ' N= ' num2str(NofEach_sorted(i))]);
%    set(ax, 'TickDir','out',...
%         'xTickLabel',unique_names,...
%         'TickLabelInterpreter', 'none',...
%         'xtick', 1:NsanesLabels, ...
%         'xTickLabelRotation',90);    
   pause;
end


