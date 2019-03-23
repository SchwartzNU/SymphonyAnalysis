function [allTimes, allEvents, allEvents_aligned, allEvents_norm, allAmp, allAmp_flat, allEvents_norm_flat] = simpleEPSC_finder(data, sampleRate, bandLow, bandHigh, thres, sampleWindow)
%sampleWindow in ms
sampleInterval = 1/sampleRate;
sampleWindow_points = round(sampleWindow * 1E-3 / sampleInterval);
%make even
if rem(sampleWindow_points,2) > 0
    sampleWindow_points = sampleWindow_points+1;
end


[Ntrials, Nsamples] = size(data);

allTimes = cell(Ntrials,1);
allEvents = cell(Ntrials,1);
allEvents_aligned = cell(Ntrials,1);
allEvents_norm = cell(Ntrials,1);
allAmp = cell(Ntrials, 1);
allAmp_flat = [];
allEvents_norm_flat = [];

z = 1;
for i=1:Ntrials
    disp(['analyzing trial ' num2str(i) ' of ' num2str(Ntrials)]);
    curData = data(i,:);
    curData_band = BandPassFilter(curData, bandLow, bandHigh, sampleInterval);
    eventTimes = getThresCross(curData_band, thres, -1);
    L = length(eventTimes);
    disp([num2str(L) ' events found']);
    allTimes{i} = eventTimes;
    allEvents{i} = zeros(L,sampleWindow_points+1);
    allEvents_aligned{i} = zeros(L,sampleWindow_points+1);
    allEvents_norm{i} = zeros(L,sampleWindow_points+1);
    allAmp{i} = zeros(L,1);
    
    for j=1:L
        if eventTimes(j) > sampleWindow_points/2 && eventTimes(j) < Nsamples - sampleWindow_points/2
            interval = eventTimes(j) - sampleWindow_points/2 : eventTimes(j) + sampleWindow_points/2;
            allEvents{i}(j,:) = curData(interval);
            bandData = curData_band(interval);
            [~, offset] = min(diff(bandData));
            alignedEvent = circshift(allEvents{i}(j,:), -offset);
            %keyboard;
            
            allEvents_aligned{i}(j,:) = alignedEvent;
            alignedEvent = alignedEvent - mean(alignedEvent(end-100:end)); %offset to end point;

            if min(alignedEvent) < 0
                allEvents_norm{i}(j,:) = alignedEvent ./ min(alignedEvent);
                allAmp{i}(j) = max(alignedEvent);
                allAmp_flat(z) = allAmp{i}(j);
                allEvents_norm_flat(z,:) = circshift(allEvents_norm{i}(j,:),  sampleWindow_points/2);
                z=z+1;
            end
        end
    end
end


