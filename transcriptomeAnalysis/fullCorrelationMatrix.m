function [uniqueTypes, fullCorrels, fullCategories, fullLabels, baseline] = fullCorrelationMatrix(D, cellTypes, directionPref, makeFigure)

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
%fullLabels = [];

baseline = corrcoef(D,'rows','pairwise');

for m=1:length(baseline)
    for n=1:length(baseline)
        %if m ~= n
        if baseline(m,n)<.9
            if string(cellTypes(m)) ~= string(cellTypes(n))
                fullCorrels = cat(2, fullCorrels, baseline(m,n));
                %disp(["At " m "x" n size(fullCorrels)]);
            else
            end
        else
        end
    end
end

fullCategories = zeros(1,length(fullCorrels));
fullLabels = ["All intertype correls"];

for i=1:Ntypes
    currentType = uniqueTypes{i};
    targetInd = find(contains(cellTypes, currentType)); 
    
    if(length(targetInd)>2);
        [subsetCorrels, subsetCategories] = cellTypeCorrelationMatrixNew(D, cellTypes, currentType);

        subsetCategories = subsetCategories+(i*2-2);

        %disp([size(subsetCategories)]);
        %disp([size(fullCategories)]);

        fullCorrels = cat(2, fullCorrels, subsetCorrels);
        fullCategories = cat(2, fullCategories, subsetCategories);

        %%%%%% This is for returning ALL correlations, both within-type and
        %%%%%%   outside-type
        %%%%%% fullLabels = cat(2, [fullLabels, currentType+" vs "+currentType, currentType+" vs Other Cells"]);
        
        %%%%%% This is for JUST within-type
        fullLabels = cat(2, [fullLabels, currentType]);
    else
    end
end

if makeFigure == 1
    figure;
     boxplot(fullCorrels,fullCategories,'OutlierSize',.1);
%         xticklabels({fullLabels});
%         xtickangle(60);
%         ylabel('Correlation Coefficient');
%     notBoxPlot(fullCorrels,fullCategories);
        xticklabels({fullLabels});
        xtickangle(60);
        ylabel('Correlation Coefficient');
        yticks([0 .25 .5 .75 1]);
        ylim([0 1]);
        title('Full Correlation Matrix');
end
    
end

