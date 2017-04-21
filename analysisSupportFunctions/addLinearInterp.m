function rootData = addLinearInterp(rootData)

if strcmp(rootData.ampMode, 'Cell attached')
    xvals = rootData.textureHalfMaxScale;
    yvals = rootData.spikeCount_stimInterval_grndBlSubt.mean_c;
   
    %Column vectors...
    [xData, yData] = prepareCurveData( xvals, yvals );

    % Set up fittype and options.
    ft = 'linearinterp';

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, 'Normalize', 'on' );
    
    rootData.fitresult = fitresult;
    rootData.gof = gof;
    
%     % get the 50% value
    [~, maxInd] = max(abs(yData));
    yMax = yData(maxInd);
    xMax = xData(maxInd);
    [~, minInd] = min(abs(yData));
    yMin = yData(minInd);
    xMin = xData(minInd);
%     ff = @(x)(feval(fitresult,x)-max(yData)/2);
%     rootData.crossing = fzero(ff, 20);
    ff = @(x)(feval(fitresult,x)-max(yData)/2);
    try
        rootData.crossing = fzero(ff, [xMin xMax]); 
    catch
        rootData.crossing = NaN;
    end;

end

end