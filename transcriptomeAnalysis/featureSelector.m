function geneInd = featureSelector(D, minThres, coeff)
[Ngenes, Ncells] = size(D);
temp = (D<minThres & D>0);
numLows = sum(temp(:));
nonZeros = sum(sum(D>0));
disp([num2str(numLows) ' low expression entries set to zero: ' num2str(100*numLows./nonZeros) '% of nonzeros.']);
D(temp) = 0;

isPresent = D>0;
fracPresent = mean(isPresent,2);
D_log = log2(D+1);
D_log_zeroToNan = D_log;
D_log_zeroToNan(D_log==0) = nan;

meanLogNonZeroExpression = nanmean(D_log_zeroToNan, 2);

%enforce present in 3+ cells
tooFewPresent = fracPresent < 3 / Ncells;
fracPresent(tooFewPresent) = nan;
meanLogNonZeroExpression(tooFewPresent) = nan;

%figure(1);
%scatter(meanLogNonZeroExpression, 1-fracPresent);

geneInd = genesAboveEquation(meanLogNonZeroExpression, 1-fracPresent, .65, coeff);
%5.5 default, try 6 or 6.5 for fewer genes
