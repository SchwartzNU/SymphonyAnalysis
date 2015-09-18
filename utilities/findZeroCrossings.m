function [zeroCrossings, directions] = findZeroCrossings(data, timeAxis, stimulusEnd, lowPassFreq, sampleInterval)
if nargin < 5
    sampleInterval = 1E-4; 
end
data = data - mean(data(timeAxis<0)); %baseline subtraction
d_smooth = LowPassFilter(data, lowPassFreq, sampleInterval);
stimPart = d_smooth(timeAxis>0 & timeAxis<stimulusEnd);
stimPart_raw = data(timeAxis>0 & timeAxis<stimulusEnd);
zeroCrossings_up = getThresCross(stimPart, 0, 1);
zeroCrossings_down = getThresCross(stimPart, 0, -1);

%because zero crossing times can get messed up by filter, choose nearest crossings from raw data
zeroCrossings_up_raw = getThresCross(stimPart_raw, 0, 1);
zeroCrossings_down_raw = getThresCross(stimPart_raw, 0, -1);

zeroCrossings_up_temp = [];
for i=1:length(zeroCrossings_up)
    D = abs(zeroCrossings_up_raw - zeroCrossings_up(i));
    [~, ind] = min(D);   
    zeroCrossings_up_temp(i) = zeroCrossings_up_raw(ind);
end
zeroCrossings_up = zeroCrossings_up_temp;

zeroCrossings_down_temp = [];
for i=1:length(zeroCrossings_down)
    D = abs(zeroCrossings_down_raw - zeroCrossings_down(i));
    [~, ind] = min(D);   
    zeroCrossings_down_temp(i) = zeroCrossings_down_raw(ind);
end
zeroCrossings_down = zeroCrossings_down_temp;


zeroCrossings = length(find(timeAxis<0)) + [zeroCrossings_down, zeroCrossings_up]; %reoffset 
directions = [-1*ones(1, length(zeroCrossings_down)), ones(1, length(zeroCrossings_up))];

[zeroCrossings, ind] = sort(zeroCrossings);
directions = directions(ind);
