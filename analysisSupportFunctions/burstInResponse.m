function burstEndTime = burstInResponse(spikeTimes, respStartTime, respEndTime)
%See history of attempts burstInResponseBEFORE121114.m, burstInResponse.m
%(121114 directory)


respSpikeTimes = spikeTimes((spikeTimes >= respStartTime) & (spikeTimes <= respEndTime));
nMean = 3;

if length(respSpikeTimes) >= nMean*2

    ISIresp = diff(respSpikeTimes);
    ISIrunningMean = zeros(1,length(ISIresp)-nMean+1);
    for I = 1:nMean
        ISIrunningMean = ISIrunningMean + ISIresp(I:end-nMean+I)./nMean;
    end;
    FRdiff = 1./ISIrunningMean(1:end-nMean) - 1./ISIrunningMean(1+nMean: end);
   
 
    
    %find burstEnd
    %[~, burstEndIndex] = find(FRdiff > Mburst, 1, 'first');
    [~, burstEndIndex] = max(FRdiff);
  
    if isempty(burstEndIndex)
        burstEndTime = NaN;
    else
        burstEndTime = respSpikeTimes(burstEndIndex+nMean);
    end;
    
else
    burstEndTime = NaN;
end
    
    
end



