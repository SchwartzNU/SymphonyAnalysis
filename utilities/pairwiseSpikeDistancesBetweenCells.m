function [Dmean, Dstd, Derr, spCount_mean] = pairwiseSpikeDistancesBetweenCells(spA, spB, Ncomparisons, cost)
Dmean = nan;
spCount_mean = nan;
Dstd = nan;
Derr = nan;

if isempty(spA) || isempty(spB)
    return
end
NA = length(spA);
NB = length(spB);

N = min([NA NB Ncomparisons]); %could do more than this

D = zeros(1, N);
spikeCounts = zeros(1,N);

if NA>NB
    R = randperm(length(spA));
    loopA = 0;
else
    R = randperm(length(spB));
    loopA = 1;
end

for i=1:N
    if loopA
        sp_1 = spA{i};
        sp_2 = spB{R(i)};
    else
        sp_1 = spB{i};
        sp_2 = spA{R(i)};
    end
    spikeCounts(i) = sqrt(length(sp_1) * length(sp_2)); %geometric mean
    D(i) = spkd(sp_1, sp_2, cost);
end

spCount_mean = mean(spikeCounts);
Dmean = mean(D);
Dstd = std(D);
Derr = Dstd./sqrt(length(D));