function [x_fit, PSTH_fit] = CHAT_fitter_sequential(PSTH, N)
span = length(PSTH);

bootStrap_N = 5;
[PSTH_max, maxLoc] = max(PSTH);
fitVals = zeros(1, bootStrap_N);
opt = optimset('Display', 'off');
PSTH_fit_M = zeros(N, span);

%first peak
x_fit_M = zeros(bootStrap_N, 3);
w = linspace(2, 25, bootStrap_N);
for i=1:bootStrap_N
    offset = maxLoc;
    h = PSTH_max;
    curParams = [w(i) h offset];
    myFun = @(x)raisedCosineFitter(x, PSTH, []);
    [x_fit_M(i,:), fitVals(i)] = fminsearch(myFun, curParams, opt);
end
%fitVals
[~, bestFitInd] = min(fitVals);
x_fit(1,:) = x_fit_M(bestFitInd, :);
PSTH_fit_M(1,:) = raisedCosine(x_fit(1,:), span);

%bisect from here
peak1_offset = round(x_fit(1,3));
peak1_w = round(x_fit(1,1));

%second peak right
ind = round(peak1_offset+peak1_w*3/2+1:span);
[peaks, peakInd] = getPeaks(PSTH(ind),1);
if ~isempty(peaks)
    [maxPeak, maxInd] = max(peaks);
    PSTH_max = maxPeak;
    offset = round(peak1_offset+peak1_w/2 + peakInd(maxInd));
else
    PSTH_max = max(PSTH(ind));
    offset = round(mean(ind));
end
h = PSTH_max;
for i=1:bootStrap_N
    curParams = [w(i) h offset-round(w(i)/2)];
    myFun = @(x)raisedCosineFitter_single(x, PSTH, []);
    [x_fit_M(i,:), fitVals(i)] = fminsearch(myFun, curParams, opt);
end
[fitVal_R, bestFitInd] = min(fitVals);
x_fit_R = x_fit_M(bestFitInd, :);

%second peak left
ind = round(1:peak1_offset+peak1_w/2-1);
[peaks, peakInd] = getPeaks(PSTH(ind),1);
if ~isempty(peaks)
    [maxPeak, maxInd] = max(peaks);
    PSTH_max = maxPeak;
    offset = round(peakInd(maxInd)) - peak1_w;
else
    PSTH_max = max(PSTH(ind));
    offset = round(mean(ind));
end
h = PSTH_max;
for i=1:bootStrap_N
    curParams = [w(i) h offset-round(w(i)/2)];
    myFun = @(x)raisedCosineFitter_single(x, PSTH, []);
    [x_fit_M(i,:), fitVals(i)] = fminsearch(myFun, curParams, opt);
end
[fitVal_L, bestFitInd] = min(fitVals);
x_fit_L = x_fit_M(bestFitInd, :);
if fitVal_R < fitVal_L
    x_fit(2,:) = x_fit_R;
    PSTH_fit_M(2,:) = raisedCosine(x_fit_R, span);
else
    x_fit(2,:) = x_fit_L;
    PSTH_fit_M(2,:) = raisedCosine(x_fit_L, span);
end

%order first two peaks
[~, peakOrder] = sort(x_fit(:,3));
x_fit = x_fit(peakOrder, :);

PSTH_fit = sum(PSTH_fit_M,1);