Response = nodeData.spikeCount_stimInterval_grndBlSubt.mean_c;
SpotSize = nodeData.spotSize;

LargeSpotI = find(abs(SpotSize - 1200)<50);
LargeSpotR = Response(LargeSpotI);
BestSpotR = max(Response);

Supressed = (BestSpotR - LargeSpotR)/BestSpotR;

Names(i) = {nodeData.cellName}
Data(i) = Supressed

i = i + 1;


%Run at beggining  Data = [] Names = {} i=1
