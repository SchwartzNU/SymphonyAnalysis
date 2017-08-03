function [F1,Vmax,Cycleavg] = gratings_Iclamp(dataMatrix,freq, sampleRate)
%This function smoothens Iclamp taces to remove spikes
%and then calculates cycle averages, F1 amplitudes
%and maximum depolarizations

cyclePts = floor(sampleRate/freq);
numCycles = floor(50000 / cyclePts);

%lowpass filter data to remove spikes
%data_lp = movmean(dataMatrix,500,2);
cycles = zeros(numCycles, cyclePts);
avgCycle = zeros(size(dataMatrix,1),cyclePts);

for i = 1 : size(dataMatrix,1)
    
    cycles = zeros(numCycles, cyclePts);
    
    for j = 1:numCycles
        index = round(((j-1)*cyclePts + (1 : floor(cyclePts))));
        cycles(j,:) =  dataMatrix(i,index);
    end
    avgCycle(i,:) = mean(cycles(2:end,:),1);
end
Cycleavg = mean(avgCycle,1)';
ft = fft(Cycleavg);
F1=abs(ft(2))/length(ft)*2;
Vmean = mean(Cycleavg);
Vmax = max(Cycleavg) - Vmean;

end

