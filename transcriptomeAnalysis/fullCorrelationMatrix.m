function [uniqueTypes, fullCorrels, fullCategories] = fullCorrelationMatrix(D, cellTypes, directionPref)

if ~isempty(directionPref)
    for i=1:length(cellTypes)
        if ~strcmp(directionPref{i}, '-')
            cellTypes{i} = [cellTypes{i} ':' directionPref{i}];
        end
    end
end

uniqueTypes = unique(cellTypes);
Ntypes = length(uniqueTypes);

% These can be used for further meta-analysis
% targetMeans = zeros(1,Ntypes); 
% targetStdevs = zeros(1,Ntypes); 
% othersMeans = zeros(1,Ntypes); 
% othersStdevs = zeros(1,Ntypes);
fullCorrels = [];
fullCategories = [];
fullLabels = [];

for i=1:Ntypes
    currentType = uniqueTypes{i};
    targetInd = find(contains(cellTypes, currentType)); 

    
    if(length(targetInd)>2);
        [subsetCorrels, subsetCategories] = cellTypeCorrelationMatrixNew(D, cellTypes, currentType);

        subsetCategories = subsetCategories+(i*2-2);

        fullCorrels = cat(2, fullCorrels, subsetCorrels);
        fullCategories = cat(2, fullCategories, subsetCategories);
        fullLabels = cat(2, [fullLabels, currentType+" vs "+currentType, currentType+" vs Other Cells"]);
        
        disp([fullLabels]);
    else
    end
end
    disp([fullLabels]);

    figure;
    boxplot(fullCorrels,fullCategories,'Notch','on');
        %'Labels',asstr(fullLabels)...
        xticklabels({fullLabels});
        xtickangle(45);
        ylabel('Correlation Coefficient');

end

