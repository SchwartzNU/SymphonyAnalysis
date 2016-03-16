function [x_fit, proj_fit] = CHAT_fitter(proj, N)
span = length(proj);

bootStrap_N = 5;
[peaks,peaksLoc] = getPeaks(proj,1);
[peaks_sorted, ind] = sort(peaks,'descend');
peaksLoc = peaksLoc(ind);
fitVals = zeros(1, bootStrap_N^2);
opt = optimset('Display', 'off');

x_fit_M = zeros(bootStrap_N, 6);
w = linspace(2, 10, bootStrap_N);
peak2_loc = linspace(10, span-10, bootStrap_N);
z=1;

%deal with 1 or zero peaks
if length(peaks) >= 2
    
    for i=1:bootStrap_N
        for j=1:bootStrap_N
            z=z+1;
            curParams = [w(i) peaks_sorted(1) peaksLoc(1) w(i) peaks_sorted(2) peak2_loc(j)];
            myFun = @(x)raisedCosineFitter(x, N, proj);
            [x_fit_M(z,:), fitVals(z)] = fminsearch(myFun, curParams, opt);
        end
    end
    %fitVals
    fitVals(fitVals==0) = Inf; %why???
    
end

[~, bestFitInd] = min(fitVals);
x_fit(1,:) = x_fit_M(bestFitInd, 1:3);
x_fit(2,:) = x_fit_M(bestFitInd, 4:6);
proj_fit = raisedCosine(x_fit(1,:), span) + raisedCosine(x_fit(2,:), span);
