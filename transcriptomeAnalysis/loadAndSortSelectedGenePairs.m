%loadAndSortSelectedGenePairs
Ntypes = 33;
Nchunks = 273;
Ncells = size(D,2);

%%
Spairs = cell(1, Ntypes);
Sscores = cell(1, Ntypes);

for i=1:Nchunks
    if exist(['selectedPairs_' num2str(i) '.mat'], 'file')
        load(['selectedPairs_' num2str(i)]);
        disp(i);
        for j=1:Ntypes
            try
                Spairs{j} = [Spairs{j}; selectedPairs{j}];
                Sscores{j} = [Sscores{j}; selectedPairScores{j}];
            catch %some selectedPairs matrices end before 33 - look into this
            end
        end
    end
end

%%
targetVals = cell(1, Ntypes);
otherVals = cell(1, Ntypes);
for i=1:Ntypes
    i
    uniqueTypes_sorted{i}
    tic;
    targetInd = strmatch(uniqueTypes_sorted{i}, cellTypes, 'exact');
    otherInd = setdiff(1:Ncells, targetInd);
    Ntarget = length(targetInd);
    Nother = Ncells - Ntarget;
    curPairs = Spairs{i};
    L = size(curPairs, 1);
    
    [scores_sorted, ind] = sort(Sscores{i},'descend');
    Sscores{i} = scores_sorted;
    curPairs_sorted = curPairs(ind);
    if L > 1E4
        curPairs_sorted = curPairs_sorted(1:1E4);
        scores_sorted = scores_sorted(1:1E4);
        L = 1E4;
    end
    Spairs_sorted{i} = curPairs_sorted;
    Sscores_sorted{i} = scores_sorted;
    
    curTargetVals = zeros(L, Ntarget, 2);
    curOtherVals = zeros(L, Nother, 2);
    for j=1:L
        gene1Ind = allPairs(curPairs_sorted(j),1);
        gene2Ind = allPairs(curPairs_sorted(j),2);
        [~, ~, D_target] = subset(D, cellTypes, cellIDs, geneNames, [gene1Ind, gene2Ind], targetInd, 0); %2 rows Ntarget columns
        [~, ~, D_other] = subset(D, cellTypes, cellIDs, geneNames, [gene1Ind, gene2Ind], otherInd, 0);%2 rows Nother columns
        curTargetVals(j, :, 1) = D_target(1,:);
        curTargetVals(j, :, 2) = D_target(2,:);
        curOtherVals(j, :, 1) = D_other(1,:);
        curOtherVals(j, :, 2) = D_other(2,:);
    end
    targetVals{i} = curTargetVals;
    otherVals{i} = curOtherVals;
    toc;
end

%%

for i=1:Ntypes
    i
    uniqueTypes_sorted{i}
    tic;
    curTarget = targetVals{i};
    curOthers = otherVals{i};
    [Npairs, Ntarget, ~] = size(curTarget);
    Nother = size(curOthers,2);
    
    %other indices to save
    meanOthers{i} = zeros(1,Npairs);
    maxOthers{i} = zeros(1,Npairs);
    meanTarget{i} = zeros(1,Npairs);
    meanLowerGeneTarget{i} = zeros(1,Npairs);
    panScore{i} = zeros(1,Npairs);
    fracPositive{i} = zeros(1,Npairs);
    fracFalsePositive{i} = zeros(1,Npairs);
    
    panTh = 100;
    panTh_low = 10;
    
    if ~isempty(curTarget)
        for j=1:Npairs
            targetVals_1 = squeeze(curTarget(j,:,1));
            targetVals_2 = squeeze(curTarget(j,:,2));
            otherVals_1 = squeeze(curOthers(j,:,1));
            otherVals_2 = squeeze(curOthers(j,:,2));
            targetVals_1_bin = targetVals_1 > panTh;
            targetVals_2_bin = targetVals_2 > panTh;
            otherVals_1_bin = otherVals_1 > panTh_low;
            otherVals_2_bin = otherVals_2 > panTh_low;

            GM_target = sqrt(targetVals_1.*targetVals_2);
            GM_others = sqrt(otherVals_1.*otherVals_2);
            meanOthers{i}(j) = mean(GM_others);
            meanTarget{i}(j) = mean(GM_target);
            maxOthers{i}(j) = max(GM_others);
            meanLowerGeneTarget{i}(j) = min([mean(targetVals_1), mean(targetVals_2)]);
            panScore{i}(j) = max([sum(otherVals_1_bin), sum(otherVals_2_bin)]);
            fracPositive{i}(j) = sum(targetVals_1 & targetVals_2) / Ntarget;
            fracFalsePositive{i}(j) = sum(otherVals_1_bin & otherVals_1_bin) / Nother;
        end
        %order by each index
        [~, order_meanOthers{i}] = sort(meanOthers{i}, 'ascend');
        [~, order_meanTarget{i}] = sort(meanTarget{i}, 'descend');
        [~, order_maxOthers{i}] = sort(maxOthers{i}, 'ascend');
        [~, order_panScore{i}] = sort(panScore{i}, 'ascend');
        [~, order_fracPositive{i}] = sort(fracPositive{i}, 'descend');
        [~, order_fracFalsePositive{i}] = sort(fracFalsePositive{i}, 'ascend');
        [~, order_meanLowerGeneTarget{i}] = sort(meanLowerGeneTarget{i}, 'descend');
        totalScore{i} = [1:Npairs] +  order_panScore{i} + order_fracPositive{i} + order_fracFalsePositive{i};
        [compositeVals{i}, compositeInd{i}] = sort(totalScore{i}, 'ascend');
    end
    toc;
end

%%
for i=1:Ntypes
    if i<=length(compositeInd)
        disp([num2str(i) ': ' uniqueTypes_sorted{i} ' CompositeInd: ' num2str(compositeInd{i}(1)) ...
            ', CompositeVal: ' num2str(compositeVals{i}(1))]);
    end
end
