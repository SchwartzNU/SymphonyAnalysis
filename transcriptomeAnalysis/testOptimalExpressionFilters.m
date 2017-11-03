function [results_meanExprVariation] = testOptimalExpressionFilters(D, cellTypes, directionPref)
% for each category, find z-score (D.prime?)
        % save the z-scores
        % try ten different floors v ten different ceilings
        % look at the maximum between those
results_meanExprVariation = [];
x = 1;
        
for floor = 0:.25:1
    x = x+1;
    y = 1;
    for ceiling = 6:1:12
        % First, label the position in the results matrix.
        y=y+1;
        results_meanExprVariation(x,1) = floor;
        results_meanExprVariation(1,y) = ceiling;
        
        %disp(results);
        
        [D_filter] = filterExpressionMatrix(D, floor, ceiling, 1);
        [uniqueTypes, fullCorrels, fullCategories, baseline] = fullCorrelationMatrix(D_filter, cellTypes, directionPref, 0);
        
        [~,~,stats] = anova1(fullCorrels, fullCategories, 'off');
        [~,m,~,~]   = multcompare(stats);
        % m is a matrix with:
        %    * the average correlation of gene expression within a type as
        %      its first column
        %    * the standard deviation of correlation of gene expression
        %      within a given type as its second column
        
        % When looking at results, we want to maximize mean correlation
        results_meanExprVariation(x,y) = mean(m(2:end,1))/m(1,1);
        %disp([floor, ceiling, p]);
    end
end
end

        
            
        
        
        