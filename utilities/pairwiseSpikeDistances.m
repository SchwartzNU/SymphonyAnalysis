function [Dmean, Dstd, Derr, spCount_mean] = pairwiseSpikeDistances(sp, cost)

N = length(sp);
D = zeros(1, floor((N-1) * (N/2))); 
z = 0;
spikeCounts = zeros(1,N);
for i=1:N
    spikeCounts(i) = length(sp{i});
    for j=i+1:N
        z=z+1;
        D(z) = spkd(sp{i}, sp{j}, cost);
    end
end

spCount_mean = mean(spikeCounts);
Dmean = mean(D);
Dstd = std(D);
Derr = Dstd./sqrt(length(D));