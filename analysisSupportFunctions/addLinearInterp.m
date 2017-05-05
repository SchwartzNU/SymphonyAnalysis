function rootData = addLinearInterp(rootData)

if strcmp(rootData.ampMode, 'Cell attached')
    xvals = rootData.halfMaxScale;
    yvals = rootData.spikeCount_stimInterval_grndBlSubt.mean_c;
   
    %Column vectors...
    [xData, yData] = prepareCurveData( xvals, yvals );

    % Set up fittype and options.
    ft = 'linearinterp';

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, 'Normalize', 'on' );
    
    rootData.fitresult = fitresult;
    rootData.gof = gof;
    
% %     % get the 50% value
%     [~, maxInd] = max(abs(yData));
%     yMax = yData(maxInd);
%     xMax = xData(maxInd);
%     [~, minInd] = min(abs(yData));
%     yMin = yData(minInd);
%     xMin = xData(minInd);
% %     ff = @(x)(feval(fitresult,x)-max(yData)/2);
% %     rootData.crossing = fzero(ff, 20);
%     ff = @(x)(feval(fitresult,x)-yMax/2);
%     try
%         rootData.crossing = fzero(ff, [xMin xMax]);
%         rootData.crossingY = max(yData)/2;
%     catch
%         rootData.crossing = NaN;
%         rootData.crossingY = NaN;
%     end;

% %     % get the 50% value
    rootData.crossing = NaN;
    rootData.crossingSup = NaN;
    rootData.crossingY = NaN;
    rootData.crossingSupY = NaN;
    [maxY,maxYind] = max(yvals);
    [minY,minYind]  = min(yvals);
    if maxY > 0
        try
            ff = @(x)(feval(fitresult,x)-maxY/2);
            rootData.crossing = fzero(ff, xvals(maxYind));
            rootData.crossingY = maxY/2;
        catch
            rootData.crossing = NaN;
            rootData.crossingY = NaN;
        end;
    end;
    if minY < 0
        try
            ff = @(x)(feval(fitresult,x)-minY/2);
            rootData.crossingSup = fzero(ff, xvals(minYind));
            rootData.crossingSupY = minY/2;
        catch
            rootData.crossingSup = NaN;
            rootData.crossingSupY = NaN;
        end;
        
    end;

end

end