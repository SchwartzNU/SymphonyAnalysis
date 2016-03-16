function [x_fit, PSTH_fit] = PSTH_fitter(PSTH, N)
span = length(PSTH);
myFun = @(x)raisedCosineFitter(x, N, PSTH);

bootStrap_N = 100;
PSTH_max = max(PSTH);
x_fit_M = zeros(bootStrap_N, N*3);
fitVals = zeros(bootStrap_N, 1);
opt = optimset('Display', 'off');

[peaks,Ind] = getPeaks(PSTH,1); %start with peaks
L = length(peaks);
if L > N
    usePeaks = true;
else
    usePeaks = false;
end

if usePeaks
    R = zeros(L, N-1);
    for i=1:N-1
        R(:,i) = randperm(L);
    end
end

for b=1:bootStrap_N
    curParams = [];        
    for i=1:N
        w = randi(50); %around 200 ms
        if usePeaks
            if b<=L
                if i==1                
                    offset = Ind(b);
                else
                    offset = Ind(R(b, i-1));
                end
            else
                offset = w*2 + randi(span - w*4);
            end
        else
            offset = w*2 + randi(span - w*4);
        end
        h = PSTH_max;
        curParams = [curParams w h offset];
    end
    [x_fit_M(b,:), fitVals(b)] = fminsearch(myFun, curParams, opt);
end

[~, bestFitInd] = min(fitVals);

x_fit = x_fit_M(bestFitInd, :);
PSTH_fit = raisedCosineSum(x_fit, N, span);
