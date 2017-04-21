function rootData = addSumOfGaussFit(rootData)
%Adam 4/2/17

xvals = rootData.spotSize;
yvals = rootData.spikeCount_stimInterval_grndBlSubt.mean_c;

%Column vectors...
[xData, yData] = prepareCurveData( xvals, yvals );

% Set up fittype and options.
ft = fittype( 'Ac*erf(x/(sc*sqrt(2)))-As*erf(x/(ss*sqrt(2)))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [0 0 50 100];
opts.StartPoint = [1 1 100 200];


% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
rootData.fitresult = fitresult;
rootData.gof = gof;

% Get max of the fit
ff = @(x)(-abs(feval(fitresult,x)));
rootData.fitMax = fminbnd(ff, 50, 600);

% %"Diagnostics"
% figure;
% plot(xvals,yvals);
% hold on;
% xfit = min(xvals):0.5:max(xvals);
% yfit = feval(rootData.fitresult, xfit);
% plot(xfit,yfit);


rootData.fitAmpCenter = fitresult.Ac;
rootData.fitAmpSur = fitresult.As;
rootData.fitSigmaCenter = fitresult.sc;
rootData.fitSigmaSur = fitresult.ss;
end