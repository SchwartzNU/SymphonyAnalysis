function plotSingleAxisStacked(fname, subStr, centers)
%Adam  11/20/14 based on 10/23/14
%range = [min max]

global TYPOLOGY_FILES_FOLDER;
pathname = TYPOLOGY_FILES_FOLDER;
load([pathname,fname,'.mat']);

W = whos;
Nvars = length(W);
figure;
hold on;
x = centers;
varNameInd = 0;
for ind = 1:Nvars
    varName = W(ind).name;
    if ~isempty(strfind(varName,subStr))
        eval(['M = ',varName,';']);
        M = M(~isnan(M));
        %plot(M, ones(1,length(M)),'DisplayName',varName,'Marker','diamond','LineStyle','none');
        varNameInd = varNameInd+1;
        y = hist(M, x);
        y = y./sum(y);
        Y(:,varNameInd) = y;
        displayNames{varNameInd} = varName;
        
    end; 
end;

bar(x,Y,'stacked');
% % Create legend
legend(displayNames);
legend('show');
set(legend,'FontSize',12);
hold off;

end

