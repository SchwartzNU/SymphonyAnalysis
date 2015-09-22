function [Dmeans_within, Dmeans_across] = spikeDistancesWithinAndAcrossCells(allCellNames, spM, cost)
Ncells = length(allCellNames)
Dmeans_within = zeros(1, Ncells);
disp('within cell')
for i=1:Ncells
    i
    [Dmeans_within(i), Dstd, Derr] = pairwiseSpikeDistances(spM{i}, cost);
end

%across cells shuffle
disp('across cells')
for i=1:Ncells
    i
    Ntrials = length(spM{i});
    randList = randperm(Ncells, Ntrials);
    sp_new = cell(1, Ntrials);
    for j=1:Ntrials
        spTemp = spM{randList(j)};        
        sp_new{j} = spTemp{randperm(length(spTemp), 1)};  %random trial from within this other cell's data
    end
    [Dmeans_across(i), Dstd, Derr] = pairwiseSpikeDistances(sp_new, cost);
end




