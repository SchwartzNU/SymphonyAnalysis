function [R, uniqueTypes, corrPValues] = corrExpressionMatrix(D, cellTypes)

%%%% In Progress %%%%

uniqueTypes = unique(cellTypes);
Ntypes = length(uniqueTypes);
corrPValues = zeros(1,Ntypes);

% Make correlation matrix comparing each cell to every other

R=corrcoef(D)

% Average correlations within cellType
for i=1:Ntypes
    currentType = uniqueTypes{i}
    disp currentType;
    
    % Grab indices of all cells of the current type... 
    targetInd = find(strcmp(currentType, cellTypes)); 
    disp([num2str(length(targetInd)) ' cells of type: ' currentType]);
    % ... And the indices every other cell too
    othersInd = setdiff(1:length(cellTypes), targetInd);  
    
    % This is not the best way to do this as it counts the ones
    %   on the diagonal. This is probably why everything looks significant
    %   now, so I'll have to fix that. Just not sure how yet. For loop?
    
    %%%  ATTEMPT 1: INCLUDE DIAGONAL 1s. NOT GOOD!
    % withinTypeCorr = mean(R(targetInd(1:length(targetInd)),targetInd(1:length(targetInd))));
    %%%
    
    %%%  ATTEMPT 2: FOR LOOP TO EXCLUDE 1s
    withinTypeCorr = zeros(1, length(targetInd));
    for i=1:length(targetInd);
        excludeCurrentCell = setdiff(targetInd, i);
        withinTypeCorr(i) = mean(R(targetInd(i), excludeCurrentCell(1:length(excludeCurrentCell))));
    end
    %%%
    
    disp(['Average correlation between ' currentType ' cells: ' num2str(withinTypeCorr)]);
        
    betweenTypeCorr = mean(R(targetInd(1:length(targetInd)), othersInd(1:length(othersInd))));
    disp(['Average correlation between ' currentType ' cells and other cells: ' num2str(betweenTypeCorr)]);
    
    % Run a t-test between the two vectors
    [~, corrPValues(i)] = ttest2(withinTypeCorr, betweenTypeCorr);
    disp(['P-Value between ' currentType ' cells and other cells: ' num2str(corrPValues(i))]);
end

end

