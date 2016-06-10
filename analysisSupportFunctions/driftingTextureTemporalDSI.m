function outputStruct = driftingTextureTemporalDSI(cellData, epochIndices)

firstEpoch = cellData.epochs(epochIndices(1));
stimTime = firstEpoch.get('stimTime') / 1000;
ampMode = firstEpoch.get('ampMode');
numEpochs = length(epochIndices);
startCutoff = firstEpoch.get('movementDelay') / 1000 + 0.3;

angles = zeros(numEpochs, 1);
for ei = 1:length(epochIndices)
    eid = epochIndices(ei);
    a = cellData.epochs(eid);
    angles(ei) = a.get('textureAngle');
end
angles = sort(unique(angles));

binLengthAlign = 0.03;
numBins = round(stimTime / binLengthAlign);
binEdgesAll = linspace(0, stimTime, numBins+1);
countsByAngleBin = zeros(length(angles), numBins);

%% make spike rate bins
for ei = 1:numEpochs
    e = cellData.epochs(epochIndices(ei));
    if strcmp(ampMode, 'Cell attached')
        spikes = e.getSpikes() / 10000;
        spikes = spikes(spikes > startCutoff);
        res = histcounts(spikes, binEdgesAll);
    end
    countsByAngleBin(angles == e.get('textureAngle'), :) = res;
end

%% temporal alignment of epochs

% bigCorr = xcorr(countsByAngleBin');
spikesByAngle = sum(countsByAngleBin, 2);
[~, refAngleI] = max(spikesByAngle);
refAngleI = find(refAngleI, 1);
refSignal = countsByAngleBin(refAngleI,:);

xcorrs = [];
for ei = 1:numEpochs
    e = cellData.epochs(epochIndices(ei));
    if strcmp(ampMode, 'Cell attached')
        spikes = e.getSpikes() / 10000;
        res = histcounts(spikes, binEdgesAll);
    end
    [x, lags] = xcorr(refSignal, res, 5); %m m m maaaagic numbers, should depend on bin size and texture scale
%     plot(lags, x)
%     pause
    xcorrs(angles == e.get('textureAngle'), :) = x;
    [~, bestLagI] = max(x);
    bestLagByAngle(angles == e.get('textureAngle')) = lags(bestLagI);
%     countsByAngleBin(angles == e.get('textureAngle'), :) = res;
end
% plot(xcorrs');

%% rebin spikes using offsets
binLengthDsi = .1;
numBins = round(stimTime / binLengthDsi);
binEdgesAllDsi = linspace(0, stimTime, numBins+1);
countsByAngleBinDsi = zeros(length(angles), numBins);

for ei = 1:numEpochs
    e = cellData.epochs(epochIndices(ei));
    if strcmp(ampMode, 'Cell attached')
        spikes = e.getSpikes() / 10000;
        offset = binLengthAlign * bestLagByAngle(angles == e.get('textureAngle'));
        spikes = spikes + offset;
        spikes = spikes(spikes > startCutoff);
        res = histcounts(spikes, binEdgesAllDsi);
    end
    countsByAngleBinDsi(angles == e.get('textureAngle'), :) = res;
end


%% make DSI and angles
numBins = size(countsByAngleBinDsi, 2);
directionVectorByTime = zeros(numBins, 1);
for ti = 1:numBins
%     countsByAngleBinDsi(:,ti);
    directionVectorByTime(ti) = sum(countsByAngleBinDsi(:,ti) .* exp(sqrt(-1) * deg2rad(angles)));
end
nor = sum(countsByAngleBinDsi, 1)';
dsiByTime = abs(directionVectorByTime ./ nor);
angleByTime = rad2deg(angle(directionVectorByTime));

%% display rates

ha = tight_subplot(2,1, .05);
axes(ha(1));
imagesc(binEdgesAllDsi(1:(end-1)), angles, countsByAngleBinDsi)
% colorbar
axes(ha(2));
plot(binEdgesAllDsi(1:end-1), dsiByTime)

%% Return output to tree
results = struct;

results.units = '';
results.type = 'combinedAcrossEpochs';
results.value = dsiByTime;

outputStruct = struct;
outputStruct.temporalDsi = results;

end

