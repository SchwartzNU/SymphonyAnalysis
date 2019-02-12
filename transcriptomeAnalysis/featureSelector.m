function geneInd = featureSelector(D, minThres, coeff, doPlot)
isLog = true;

[Ngenes, Ncells] = size(D);
temp = (D<minThres & D>0);
numLows = sum(temp(:));
nonZeros = sum(sum(D>0));
disp([num2str(numLows) ' low expression entries set to zero: ' num2str(100*numLows./nonZeros) '% of nonzeros.']);
D(temp) = 0;

isPresent = D>0;
fracPresent = mean(isPresent,2);

if ~isLog
    D_log = log10(D+1);
    D_log_zeroToNan = D_log;
else
    D_log = D;
    clear('D');
    D_log_zeroToNan = D_log;
end

size(D_log)
D_log_zeroToNan(D_log==0) = nan;
clear('D_log');

size(D_log_zeroToNan)

meanLogNonZeroExpression = nanmean(D_log_zeroToNan, 2);
size(meanLogNonZeroExpression)

%enforce present in 3+ cells
tooFewPresent = fracPresent < 3 / Ncells;
fracPresent(tooFewPresent) = nan;
meanLogNonZeroExpression(tooFewPresent) = nan;

geneInd = [];
%[geneInd, x, y] = genesAboveEquation(meanLogNonZeroExpression, 1-fracPresent, .65, coeff);
keyboard;
if doPlot
    figure(1);
    scatter(meanLogNonZeroExpression, 1-fracPresent, 'bx');
    %hold on;
    %plot(x, y, 'r');
    %set(gca,'ylim',[0, 1]);
    %hold off;
end

%5.5 default, try 6 or 6.5 for fewer genes
