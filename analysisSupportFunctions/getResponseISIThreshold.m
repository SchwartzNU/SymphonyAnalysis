function [blistQshort, baselineISI, blistQ10, blistQ90] = getResponseISIThreshold(blISI, blISI2)
Nepochs = length(blISI);

baselineISI = [];
baselineISI2 = [];
p2 = 0; %2 spikes observed
p3 = 0; %3 spikes obserevd
for j = 1:Nepochs
    baselineISI = [baselineISI, blISI{j}];
    baselineISI2 = [baselineISI2,blISI2{j}];
    if ~isempty(blISI2{j})
        p2 = p2+1/Nepochs;
        if length(blISI2{j}) > 1
            p3 = p3+1/Nepochs;
        end;
    end;
end;
if ~isempty(baselineISI)
    blistQ10 = quantile(baselineISI, 0.1);
    blistQ90 = quantile(baselineISI, 0.9);
else
    blistQ10 = Inf;
    blistQ90 = Inf;
end;

if ~isempty(baselineISI2)
    %this is for the pdf of (Ti + Ti+1) !!    
    probAtLeast3spks = p3;
    if probAtLeast3spks >1
        probAtLeast3spks = 1;
    end;
    
    probThreshold = 0.1/probAtLeast3spks;
    if probThreshold >1
        probThreshold = 1;
    end;
    blistQshort = quantile(baselineISI2, probThreshold);
else    
    blistQshort = Inf;
end;