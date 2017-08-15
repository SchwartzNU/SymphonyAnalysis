function [allCorrels, categories] = cellTypeCorrelationMatrixNew(D, cellTypes, currentType)

targetInd = find(contains(cellTypes, currentType)); 
othersInd = setdiff(1:length(cellTypes), targetInd);

if(length(targetInd)<3);
    withinTypeCorr = 0;
    disp(['Not enough ' currentType ' s to achieve statistical significance.' newline]);
    targetMean = NaN;
    targetStd = NaN;
    othersMean = NaN;
    othersStd = NaN;
    allCorrels = NaN;
    categories = NaN;
    
else

    % Make an x*2 matrix that lists every combination of target cells
    targetIndCombinations = nchoosek(targetInd,2);
    
    % Find correlations of all  combinations of those on-target guys and
    % put them in a vector. This is the way to avoid self-correlation.
    targetIndCorrelations = zeros(1,length(targetIndCombinations));

    for j=1:length(targetIndCombinations)
        targetIndCorrelations(j) = corr(D(1:end,targetIndCombinations(j,1)), D(1:end,targetIndCombinations(j,2)));
    end
    
    % Others
    othersIndCorrelations = zeros(length(targetInd),length(othersInd));
    
    for j=1:length(targetInd)
        for k=1:length(othersInd)
            othersIndCorrelations(j,k) = corr(D(1:end,targetInd(j)),D(1:end,othersInd(k)));
        end
    end

    othersIndCorrelations = reshape(othersIndCorrelations,1,[]);

    allCorrels = [targetIndCorrelations,othersIndCorrelations];
    categories = [ones(1,length(targetIndCorrelations)),2*(ones(1,length(othersIndCorrelations)))];

    %%%  Making a figure - uncomment the below for single figures %%%
%     figure;
%     allCorrels = [targetIndCorrelations,othersIndCorrelations];
%     categories = [ones(1,length(targetIndCorrelations)),zeros(1,length(othersIndCorrelations))];
%     boxplot(allCorrels,categories,'Notch','on',...
%         'Labels',{'Target Cells vs Other Cells','Target vs Target Cells'});
%         title(currentType);
%         ylabel('Correlation Coefficient');
% 
    targetMean = mean(targetIndCorrelations);
    othersMean = mean(othersIndCorrelations);
    targetStd  = std(targetIndCorrelations);
    othersStd  = std(othersIndCorrelations);

    disp(['Mean Correlation (' currentType ' vs ' currentType '):' num2str(targetMean) '; StdDv: ' num2str(targetStd)]);
    disp(['Mean Correlation (' currentType ' vs other cells):' num2str(othersMean) '; StdDv: ' num2str(othersStd) newline]);

end
    

