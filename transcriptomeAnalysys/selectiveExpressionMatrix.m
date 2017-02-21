function [D_sorted, D_target, D_others, D_origOrder, indexVals_sorted, geneNames_sorted, targetInd, othersInd] = selectiveExpressionMatrix(D, cellTypes, geneNames, selection, Ngenes, method)
if ischar(selection)
    selectedType = selection;
    targetInd = find(strcmp(selectedType, cellTypes));
    disp([num2str(length(targetInd)) ' cells of type: ' selectedType]);
    othersInd = setdiff(1:length(cellTypes), targetInd);
else
    targetInd = selection;
    disp([num2str(length(targetInd)) ' cells selected.']);
    othersInd = setdiff(1:length(cellTypes), targetInd);
end


thresVal = 10;
N = length(geneNames);
indexVals = zeros(N,1);
switch method
    case 'log-ratio'
        D(D<2) = 1;
        logD = log10(D);
        for i=1:N
            targetMed = median(logD(i,targetInd));
            otherMed = median(logD(i,othersInd));
            indexVals(i) = targetMed - otherMed;
        end
        
    case 'threshold'
        D_thres = D>thresVal;
        for i=1:N
            targetFrac = sum(D_thres(i,targetInd))./length(targetInd);
            otherFrac = sum(D_thres(i,othersInd))./length(targetInd);
            indexVals(i) = targetFrac - otherFrac;
        end
        
    case 'p-value'
        D(D<10) = 1;
        logD = log10(D);
        for i=1:N
            targetVals = logD(i,targetInd);
            otherVals = logD(i,othersInd);
            [~, indexVals(i)] = ttest2(targetVals, otherVals, 'tail', 'right');
        end
end
    
[indexVals_sorted, ind] = sort(indexVals, 'ascend');
geneNames_sorted = geneNames(ind);

geneNames_sorted = geneNames_sorted(1:Ngenes);
D(D<3) = 0;
D_origOrder = D(ind(1:Ngenes), :);
D_target = D(ind(1:Ngenes), targetInd);
D_others = D(ind(1:Ngenes), othersInd);
D_sorted = [D_target, D_others];



%method is one of the following options:
% threshold
% log-ratio
% p-value



