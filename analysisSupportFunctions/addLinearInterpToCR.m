function rootData = addLinearInterpToCR(rootData)

AM = '';
try 
    AM = rootData.ampMode;
catch
    AM = rootData.amp2Mode;
end

if strcmp(AM, 'Cell attached')
    xvals = rootData.contrast;
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
    %     ff = @(x)(feval(fitresult,x)-max(yData)/2);
    %     rootData.crossing = fzero(ff, 20);
    
    %Positive contrast
    rootData.onCrossing = NaN;
    rootData.onCrossingSup = NaN;
    rootData.onCrossingY = NaN;
    rootData.onCrossingSupY = NaN;
    xvalsPos = xvals(xvals>=0);
    yvalsPos = yvals(xvals>=0);
    [maxYpos,maxYposInd] = max(yvalsPos);
    [minYpos,minYposInd]  = min(yvalsPos);
    if maxYpos > 0
        ff = @(x)(feval(fitresult,x)-maxYpos/2);
        rootData.onCrossing = fzero(ff, xvalsPos(maxYposInd));
        rootData.onCrossingY = maxYpos/2;
    end;
    if minYpos < 0
        ff = @(x)(feval(fitresult,x)-minYpos/2);
        rootData.onCrossingSup = fzero(ff, xvalsPos(minYposInd));
        rootData.onCrossingSupY = minYpos/2;
    end;
    
    %Negative contrast
    rootData.offCrossing = NaN;
    rootData.offCrossingSup = NaN;
    rootData.offCrossingY = NaN;
    rootData.offCrossingSupY = NaN;
    xvalsNeg = xvals(xvals<=0);
    yvalsNeg = yvals(xvals<=0);
    [maxYneg,maxYnegInd] = max(yvalsNeg);
    [minYneg,minYnegInd]  = min(yvalsNeg);
    if maxYneg > 0
        ff = @(x)(feval(fitresult,x)-maxYneg/2);
        rootData.offCrossing = fzero(ff, xvalsNeg(maxYnegInd));
        rootData.offCrossingY = maxYneg/2;
    end;
    if minYneg < 0
        ff = @(x)(feval(fitresult,x)-minYneg/2);
        rootData.offCrossingSup = fzero(ff, xvalsNeg(minYnegInd));
        rootData.offCrossingSupY = minYneg/2;
    end;
    
    
end

end