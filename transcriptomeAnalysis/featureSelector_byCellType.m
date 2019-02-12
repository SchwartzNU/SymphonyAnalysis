function [geneInd, x, y]  = featureSelector_byCellType(D, targetCellInd, minThres, coeff)
[Ngenes, Ncells] = size(D);

otherCellInd = setdiff(1:Ncells, targetCellInd);

temp = (D<minThres & D>0);
numLows = sum(temp(:));
nonZeros = sum(sum(D>0));
disp([num2str(numLows) ' low expression entries set to zero: ' num2str(100*numLows./nonZeros) '% of nonzeros.']);
D(temp) = 0;

D_target = D(:, targetCellInd);
D_other = D(:, otherCellInd);

isPresent_T = D_target>0;
fracPresent_T = mean(isPresent_T,2);

isPresent_O = D_other>0;
fracPresent_O = mean(isPresent_O,2);

D_log = log10(D+1);
D_log_zeroToNan = D_log;
D_log_zeroToNan(D_log==0) = nan;

D_log_T = D_log(:, targetCellInd);
D_log_zeroToNan_O = D_log_zeroToNan(:, otherCellInd);

meanLogExpression_T = nanmean(D_log_T, 2);
meanLogNonZeroExpression_O = nanmean(D_log_zeroToNan_O, 2);

%enforce present in 3+ cells
tooFewPresent = fracPresent_T < 3 / Ncells;
fracPresent_T(tooFewPresent) = nan;
meanLogExpression_T(tooFewPresent) = nan;

geneInd = [];
%figure(1);
%subplot(1,2,1);
x = meanLogExpression_T;
y = 1-fracPresent_O;
%scatter(meanLogExpression_T, 1-fracPresent_O);
%xlabel('Mean log expression (target)');
%ylabel('Fraction absent (other)');
%subplot(1,2,2);
%scatter(meanLogNonZeroExpression_O, 1-fracPresent_T);
%xlabel('Mean log nonzero expression (other)');
%ylabel('Fraction absent (target)');

%cftool(meanLogNonZeroExpression_T, 1-fracPresent_O);

%geneInd = genesAboveEquation(meanLogNonZeroExpression, 1-fracPresent, .65, coeff);
%5.5 default, try 6 or 6.5 for fewer genes
