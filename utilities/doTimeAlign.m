function [ C, P, T, AHP, FWHM, initSlope, preSlope, threshSlope, maxSlope ] = doTimeAlign( voltages, spikeTimes, sampR, len, clamp, f )
% This function calculates parameters of a spike
%   INPUT: voltages from an epoch, approximate spike times, desired length (must be odd),
%   and if you want figures displayed.
%   ADD: sampling frequency parameter
%   FIX: odd numbers only for len
%   OUTPUT: time aligned voltages, peaks, threshold, ahp, fwhm, init slope
%   and figures if 'figures' is imputted for f

if (size(voltages, 1) > size(voltages, 2))
    voltages = voltages';
end
if sampR ~= 50000
    timeAxis = [0:length(voltages)-1]/sampR;
    voltages = interp1(timeAxis, voltages, linspace(0, timeAxis(end), ceil(length(voltages)*(50000/sampR))), 'spline');
    len = ceil(50000/sampR*len);
    spikeTimes = ceil(spikeTimes*(50000/sampR));
    sampR = 50000;
end
if (mod(len, 2) == 0)
    len = len+1;
end
factor = sampR/1000;
L = length(voltages);
lenVec = 1:len;
N = length(spikeTimes);
C = nan(N, len); % voltages traces
P = nan(N, 1); % peaks
T = nan(N, 1); % thresholds
AHP = nan(N, 1); % amplitude of the after hyperpolarization mV
FWHM = nan(N, 1); % full width at half max in ms
initSlope = nan(N, 1); % slope between the threshold and halfMax (mV/ms)
preSlope = nan(N, 1); % slope before the threshold (mV/ms)
threshSlope = nan(N, 1); % slope at the threshold (mV/ms)
maxSlope = nan(N, 1); % max slope of dVdt (mV/ms)
for i = 1:N
    st = spikeTimes(i);
    if st <= 15 || st >= L-100 % can't calculate threshold
        continue
    end
    if strcmp(clamp, 'CC') || strcmp(clamp, 'IC')
        [peak, I] = max(voltages(st-15: st+100));
        [ahp, AHPInd] = min(voltages(st: min(st+(25*(sampR/10000)), L)));
        AHPInd = AHPInd+15;
    elseif strcmp(clamp, 'VC')
        [peak, I] = min(voltages(st-15: st+15));
        [ahp, AHPInd] = max(voltages(st: min(st+(25*(sampR/10000)), L)));
        AHPInd = AHPInd+15;
    elseif strcmp(clamp, 'EX_upSpikes')
        [peak, I] = max(voltages(st-15: st+15));
        [ahp, AHPInd] = min(voltages(st: min(st+(25*(sampR/10000)), L)));
        AHPInd = AHPInd+15;
    elseif strcmp(clamp, 'EX_downSpikes')
        [peak, I] = min(voltages(st-15: st+15));
        [ahp, AHPInd] = max(voltages(st: min(st+(25*(sampR/10000)), L)));
        AHPInd = AHPInd+15;
    else
        disp('Clamp option not valid')
        break
    end
    
    half = floor(len/2);
    I = st+I-15-1;
    c = [];
    if length(voltages) == len
        c = voltages;
    elseif (st - half <= 0) | (st + half > L)
        % to close to edge
        continue
    else
        c = voltages(st-half:st+half);
    end
    c = nanmean(c, 1);
    
    
    %%% fix finding threshold
    thresholdV = 0;
    dVdt = diff(c);
    ddVdt = diff(dVdt);
    thresholdInd = max(find((ddVdt > mean(ddVdt)+3*var(ddVdt)), 1) - 3, 1);
    if (sampR==50000) && (strcmp(clamp, 'CC') || strcmp(clamp, 'IC'))
        third = ceil(length(c)/3);
        ddVdt = diff(dVdt(1+third:end-third));
        thresholdInd = max(find((ddVdt > mean(ddVdt)+5*var(ddVdt)), 1) - 3, 1);
        thresholdInd = thresholdInd+third;
    end
    if isempty(thresholdInd) && (strcmp(clamp, 'CC') || strcmp(clamp, 'IC'))
        thresholdInd = max(find((ddVdt > mean(ddVdt)+var(ddVdt)), 1) - 3, 1);
    elseif isempty(thresholdInd) && strcmp(clamp, 'VC')
        thresholdInd = max(find((ddVdt > mean(ddVdt)+std(ddVdt)), 1) - 3, 1);
    elseif strcmp(clamp, 'EX_upSpikes') % so noisy that the other method doesn't work
        [~, thresholdI] = min(c(floor(len/2)-15:floor(len/2)));
        thresholdInd = thresholdI + floor(len/2) -15;
    elseif strcmp(clamp, 'EX_downSpikes') % so noisy that the other method doesn't work
        figure; scatter(c(2:end), dVdt)
        [~, thresholdI] = max(c(half-15*(sampR/10000):half));
        thresholdInd = thresholdI + floor(len/2) -15;
    end
    if thresholdInd == 1
        thresholdInd = max(find((ddVdt > mean(ddVdt)+20*var(ddVdt)), 1) - 3, 1);
    end
    if ~isempty(thresholdInd)
        thresholdV = c(thresholdInd);
    else
        continue
    end    
%     thresholdInd
    
    smallSize = 20;
    smallLenVec = lenVec(floor(len/2)-smallSize:floor(len/2)+smallSize);
    smallC = c(smallLenVec);
    
    halfMax = (peak - thresholdV)/2 + thresholdV;
    if (strcmp(clamp, 'CC') || strcmp(clamp, 'IC'))
        startHalf = min(smallLenVec(smallC>halfMax));
        endHalf = max(smallLenVec(smallC>halfMax));
    elseif strcmp(clamp, 'VC')
        startHalf = min(smallLenVec(smallC<halfMax));
        endHalf = max(smallLenVec(smallC<halfMax));
    elseif strcmp(clamp, 'EX_upSpikes')
        startHalf = min(smallLenVec(smallC>halfMax));
        endHalf = max(smallLenVec(smallC>halfMax));
    elseif strcmp(clamp, 'EX_downSpikes')
        startHalf = min(smallLenVec(smallC<halfMax));
        endHalf = max(smallLenVec(smallC<halfMax));
    end
    
    
    if thresholdInd > startHalf
        continue
%         thresholdInd
%         startHalf
%         figure; plot(c)
%         thresholdInd = max(find(c(1:I) < thresholdV));
%         
%         if isempty(thresholdInd)
%             continue
%         end
    end
    
    if strcmp(f, 'figures') && i == 1
        figure
        hold on
        plot(lenVec/factor, c)
        scatter(floor(len/2)/factor, peak, 'm')
        plot([1, len]/factor, [thresholdV, thresholdV], 'r')
        scatter((AHPInd+half-15)/factor, ahp, 'g') 
        plot([startHalf, endHalf]/factor, [halfMax, halfMax], 'k')
        xlabel('msec'); ylabel('mV');
        legend('Voltages Trace', 'Peak', 'Threshold', 'AHP', 'FWHM')
        hold off

        V = c(2:end);
        figure
        scatter(V, dVdt)
        
    end


    
    % assign things
    if ~isempty(endHalf) || ~isempty(startHalf)
        C(i, :) = c;
        P(i, 1) = peak;
        T(i, 1) = thresholdV;
        AHP(i, 1) = ahp;
        FWHM(i, 1) = (endHalf-startHalf)/factor; % in ms
        initSlope(i, 1) = (halfMax - thresholdV)/(startHalf/factor - thresholdInd/factor);
        preSlope(i, 1) = (thresholdV - c(1))/(thresholdInd/factor - 0);
        try
            threshSlope(i, 1) = (c(thresholdInd+1) - c(thresholdInd-1))/((thresholdInd+1)/factor - (thresholdInd-1)/factor);
        catch
            preSlope(i, 1) = NaN;
            threshSlope(i, 1) = NaN;
        end
        maxSlope(i, 1) = max(dVdt)/(1/factor);
    end
    
end


end

