function rootData = addSMSmetaParams(rootData, spotSizeParam)
%Xmax, Xwidth, YinfOverYmax, Xcutoff, absValueSpot300.


fnames = fieldnames(rootData);
numParamsMeta = length(fnames);
spotSize = rootData.(spotSizeParam);

for paramInd=1:numParamsMeta
    curField = fnames{paramInd};
    if isfield(rootData.(curField), 'type')
        respVals = getRespVectors(rootData, {curField});
        
        if ~isempty(respVals)
            

            %interpolation
            spotSizeInterp = spotSize(1):10:spotSize(end);
            if length(respVals(~isnan(respVals))) > 1
                respValsInterp = interp1(spotSize,respVals, spotSizeInterp);
            else
                respValsInterp = respVals;
                spotSizeInterp = spotSize;
            end;
            % %
            
            [maxVal, maxInd] = max(respVals);
            Xmax = spotSize(maxInd);
            infVal = mean(respVals(max(end-2,1): end)); %"asymptotic" value.
            YinfOverYmax = infVal/maxVal;
            
            halfMaxLeftInd = find(respValsInterp > (maxVal-infVal)/2, 1, 'first');
            halfMaxRightInd = find(respValsInterp > (maxVal-infVal)/2, 1, 'last');
            Xwidth = spotSizeInterp(halfMaxRightInd) - spotSizeInterp(halfMaxLeftInd);
            
            cutoffInd = find(respValsInterp > maxVal/4, 1, 'last');
            Xcutoff = spotSizeInterp(cutoffInd);
            
            [~, spot300index] = min(abs(spotSizeInterp - 300));
            absValueSpot300 = respValsInterp(spot300index);
            
            rootData.([curField,'_Xmax']) = Xmax;    
            rootData.([curField,'_YinfOverYmax']) = YinfOverYmax; %asymptotic value/maximum
            rootData.([curField,'_Xwidth']) = Xwidth;
            rootData.([curField,'_Xcutoff']) = Xcutoff;
            rootData.([curField,'_absMax']) = maxVal;
            rootData.([curField,'_absValueSpot300']) = absValueSpot300;
            
%             figure(20);
%             plot(spotSizeInterp, respValsInterp);
%             keyboard;
        end;

    end
end

end