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

N = length(geneNames);
indexVals = zeros(N,1);
switch method
    case 'log-ratio'
        D=D*1000; %make the minimum about 14
        D(D<2) = 1;
        logD = log10(D);
        for i=1:N
            targetMed = median(logD(i,targetInd));
            otherMed = median(logD(i,othersInd));
            indexVals(i) = targetMed - otherMed;
        end
        [indexVals_sorted, ind] = sort(indexVals, 'descend');
        
    case 'threshold'
        thresVal = .1;
        D_thres = D>thresVal;
        falseNeg_scaling = 0.35;
        for i=1:N
            targetFrac = sum(D_thres(i,targetInd))./length(targetInd);
            otherFrac = sum(D_thres(i,othersInd))./length(targetInd);
      
            %indexVals(i) = targetFrac - otherFrac;
            indexVals(i) = falseNeg_scaling*targetFrac - (1-falseNeg_scaling)*otherFrac;
        end
        [indexVals_sorted, ind] = sort(indexVals, 'descend');
        
    case 'p-value'
        D=D*1000; %make the minimum about 14
        D(D<2) = 1;
        logD = log10(D);
        for i=1:N
            targetVals = logD(i,targetInd);
            otherVals = logD(i,othersInd);
            [~, indexVals(i)] = ttest2(targetVals, otherVals, 'tail', 'right');
        end
        [indexVals_sorted, ind] = sort(indexVals, 'ascend');
        
   case 'multi-step' %p-value and then more processing after
        D=D*1000; %make the minimum about 14
        D(D<2) = 1;
        logD = log10(D);
        for i=1:N
            targetVals = logD(i,targetInd);
            otherVals = logD(i,othersInd);
            [~, indexVals(i)] = ttest2(targetVals, otherVals, 'tail', 'right');
        end
        [indexVals_sorted, ind] = sort(indexVals, 'ascend');
end
    
geneNames_sorted = geneNames(ind);

geneNames_sorted = geneNames_sorted(1:Ngenes);
D_origOrder = D(ind(1:Ngenes), :);
D_target = D(ind(1:Ngenes), targetInd);
D_others = D(ind(1:Ngenes), othersInd);
D_sorted = [D_target, D_others];

%method is one of the following options:
% threshold
% log-ratio
% p-value



