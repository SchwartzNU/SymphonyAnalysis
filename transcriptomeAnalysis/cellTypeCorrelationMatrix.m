function [uniqueTypes, corrPValues] = cellTypeCorrelationMatrix(D, cellTypes, directionPref, graph)
if ~isempty(directionPref)
    for i=1:length(cellTypes)
        if ~strcmp(directionPref{i}, '-')
            cellTypes{i} = [cellTypes{i} ':' directionPref{i}];
        end
    end
end

uniqueTypes = unique(cellTypes);
Ntypes = length(uniqueTypes);
corrPValues = zeros(1,Ntypes);

D = D*1000;
D(D<2) = 1;
D = log(D);

% Make correlation matrix comparing each cell to every other
R=corrcoef(D);

% Average correlations within cellType
for i=1:Ntypes
    currentType = uniqueTypes{i};
    
    % Grab indices of all cells of the current type... 
    targetInd = find(strcmp(currentType, cellTypes)); 
    
    if(length(targetInd)<3);
        withinTypeCorr = 0;
        disp(['Not enough ' currentType ' s to achieve statistical significance.' newline]);
        corrPValues(i) = NaN;
        
    else
        targetIndCombinations = nchoosek(targetInd,2);
    	disp([num2str(length(targetInd)) ' cells of type: ' currentType]);
    
        % ... And the indices every other cell too
        othersInd = setdiff(1:length(cellTypes), targetInd);  
    
        withinTypeCorr = zeros(1, length(targetIndCombinations));
    
        for ci=1:length(targetIndCombinations);
            withinTypeCorr(ci) = R(targetIndCombinations(ci,1),(targetIndCombinations(ci,2)));
        end
        
        disp(['All correlations between ' currentType ' cells:' num2str(withinTypeCorr)]);
        withinTypeCorrAvg = mean(withinTypeCorr);
        disp(['Average correlation between ' currentType ' cells: ' num2str(withinTypeCorrAvg)]);
        
        % Between Types    
        betweenTypeCorr = reshape(R(targetInd(1:length(targetInd)), othersInd(1:length(othersInd))),1,[]);
        betweenTypeCorrAvg = mean(betweenTypeCorr);
    
        disp(['All correlations between ' currentType ' cells and other cells: ' num2str(betweenTypeCorr)]);
        disp(['Average correlation between ' currentType ' cells: ' num2str(betweenTypeCorrAvg)]);
    
        % Run a t-test between the two vectors
        [~, corrPValues(i)] = ttest2(withinTypeCorr, betweenTypeCorr);
        disp(['P-Value between ' currentType ' cells and other cells: ' num2str(corrPValues(i)) newline]);
    end
end

if(graph == 1)
    figure;
    semilogy([1:length(corrPValues)], corrPValues, 'bx');

    xticks(1:length(uniqueTypes));
    xticklabels(uniqueTypes);
    xtickangle(45);
    
    signif = refline(0,0.05);
    signif.Color = 'r';
    
    grid on;
else
end

end

