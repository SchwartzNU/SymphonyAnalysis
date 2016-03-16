function [spikeAmps, averageWaveform] = getSpikeAmplitudes(trace, spikeTimes)
%assumes 10 kHz sample rate (for now)
L = length(spikeTimes);
spikeAmps = zeros(L,1);
waveformMatrix = zeros(L, 41);

if isnan(spikeTimes)
    spikeAmps = NaN;
    averageWaveform = nan;
    return;
end

for i=1:L
   if spikeTimes(i) < 21 || spikeTimes(i) > length(trace) - 20  %need 2 ms before and after
       spikeTimes(i) = nan;
   else
       segment = trace(spikeTimes(i) - 20 : spikeTimes(i) + 20);
       indAxis = -20:20;
       segment = segment - mean(segment);
       [negPeakAmps, negPeakInd]  = getPeaks(segment, -1);
       [posPeakAmps, posPeakInd] = getPeaks(segment, 1);       
       [maxNeg, maxNegInd] = min(negPeakAmps);
       [maxPos, maxPosInd] = max(posPeakAmps);
       
       spikeNegPeakInd = negPeakInd(maxNegInd);
       spikePosPeakInd = posPeakInd(maxPosInd);
       %peakDiff = spikePosPeakInd - spikeNegPeakInd;
       spikeAmps(i) = segment(spikePosPeakInd) - segment(spikeNegPeakInd);
       waveformMatrix(i,:) = circshift(segment,20+spikeNegPeakInd) ./ spikeTimes(i); 
   end
end
averageWaveform = mean(waveformMatrix);

