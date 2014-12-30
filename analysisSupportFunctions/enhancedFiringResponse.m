function [ONresponseStartTime, ONresponseEndTime, OFFresponseStartTime, OFFresponseEndTime] = enhancedFiringResponse(spikeTimes, ONstartTime, ONendTime, blistQshort)
%Written by Adam Mani, Shcwartz lab NU
%Ver. 1 Dec.2014

%separation into ON/OFF constants
M = 3;
M2 = 2;
winStart = 0.05; %s
winEnd = 0.4; %s

spikeTimesResp = spikeTimes(spikeTimes > ONstartTime + winStart);
ISIresp = diff(spikeTimesResp);
v = ISIresp;
v1left = [v(2:end), inf];
twoConsecutiveUnderQshort = (v + v1left < blistQshort);
if ~isempty(twoConsecutiveUnderQshort)&& ~all(~twoConsecutiveUnderQshort)
    enhancedFiringIndices = ([twoConsecutiveUnderQshort 0] | [0 twoConsecutiveUnderQshort]) | [0 0 twoConsecutiveUnderQshort(1:end-1)];
    firstSpikeTime = spikeTimesResp(find(enhancedFiringIndices, 1, 'first'));
    lastSpikeTime = spikeTimesResp(find(enhancedFiringIndices, 1, 'last'));
    enhancedFiringTimes = spikeTimesResp( (spikeTimesResp >= firstSpikeTime) & (spikeTimesResp <= lastSpikeTime) );
else
    enhancedFiringTimes = [];
%     ONresponseStartTime = [];
%     ONresponseEndTime = [];
%     OFFresponseStartTime = [];
%     OFFresponseEndTime = [];
end;

%if ~isempty(enhancedFiringTimes)
if (sum(enhancedFiringTimes <= ONendTime+winStart) >=3) || (sum(enhancedFiringTimes > ONendTime+winStart) >=3)
    %TEMP less than 3 spikes in ON are not treated. Otherwise error ln. 76.
    if firstSpikeTime <= ONendTime+winStart  %Have ON response.
        ONresponseStartTime = firstSpikeTime;
        
        %Check whether to separate into ON/OFF
        if (enhancedFiringTimes(end-2) > ONendTime+winStart) %3 spikes into OFF (otherwise no OFF).
            
            spikeTimesSplitWindow = enhancedFiringTimes((enhancedFiringTimes > ONendTime+winStart) & (enhancedFiringTimes < ONendTime+winEnd));
            spikeTimesSplitWindow = [enhancedFiringTimes(find(enhancedFiringTimes <= ONendTime+winStart, 1, 'last')), spikeTimesSplitWindow];
            
            if length(spikeTimesSplitWindow) < 3
                %ON response + a very late OFF response, latency > winEnd
                ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp<ONendTime+winEnd, 1, 'last') );
                OFFresponseStartTime = spikeTimesResp(find(enhancedFiringIndices & spikeTimesResp >= ONendTime+winEnd, 1, 'first') );
                OFFresponseEndTime = lastSpikeTime;
            else
                %added the last spike before stimulus OFF.
                ISIsplitWindow = diff(spikeTimesSplitWindow);
                %                           ISIratioSplitWindow = ISIsplitWindow(1:end-1)./ISIsplitWindow(2:end);
                ISIratioSplitWindow = ISIsplitWindow(1:end-2)./(ISIsplitWindow(2:end-1)+ISIsplitWindow(3:end));
                OFFrespStartIndex = find(ISIratioSplitWindow > M, 1, 'first') +1;
                
                if ~isempty(OFFrespStartIndex) %separted into ON+OFF
                    OFFresponseStartTime = spikeTimesSplitWindow(OFFrespStartIndex);
                    %OFFresponseStartTime found, now find ONresponseEndTime using triplet condition.
                    %Find triplet that satisfies the condition, and is before OFFresponseStartTime
                    ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp < OFFresponseStartTime, 1, 'last') );
                    OFFresponseEndTime = lastSpikeTime;
                else %no separation => only ON.
                    ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp<ONendTime+winEnd, 1, 'last') );
                    OFFresponseStartTime = [];
                    OFFresponseEndTime = [];
                end;
            end;
            
        else %No 3 spikes in OFF => only ON response.
            % ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp<ONendTime+winStart, 1, 'last') );
            OFFresponseStartTime = [];
            OFFresponseEndTime = [];
            
            if sum(enhancedFiringTimes > ONendTime+winStart) > 0 %1 or 2.
                %Check what to do with extra spikes (dump/extend ON)
                firstAdditionalSpikeIndex = find(enhancedFiringTimes > ONendTime+winStart, 1, 'first');
                spikeTimesSplitWindow = enhancedFiringTimes(firstAdditionalSpikeIndex-3 : firstAdditionalSpikeIndex);
                %Try to separate to left on the time axis
                ISIsplitWindow = diff(spikeTimesSplitWindow);
                ISIratioSplitWindow = ISIsplitWindow(3)/(ISIsplitWindow(1)+ISIsplitWindow(2));
                if ISIratioSplitWindow > M2
                    ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp<ONendTime+winStart, 1, 'last') );
                    %ditch the spikes
                else
                    ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp<ONendTime+winEnd, 1, 'last') );
                    %keep the spikes
                end
            else
                ONresponseEndTime = spikeTimesResp( find(enhancedFiringIndices & spikeTimesResp<ONendTime+winStart, 1, 'last') );
                %should be =lastSpikeTime
            end;
            
        end;
        
    else %No ON response
        OFFresponseStartTime = firstSpikeTime;
        OFFresponseEndTime = lastSpikeTime;
        ONresponseStartTime = [];
        ONresponseEndTime = [];
    end;
else %No response at all
    OFFresponseStartTime = [];
    OFFresponseEndTime = [];
    ONresponseStartTime = [];
    ONresponseEndTime = [];
end;

% %adjust off resp times
% if ~isempty(OFFresponseStartTime), OFFresponseStartTime = OFFresponseStartTime + ONendTime; end
% if ~isempty(OFFresponseEndTime), OFFresponseEndTime = OFFresponseEndTime + ONendTime; end

end