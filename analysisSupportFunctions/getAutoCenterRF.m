function outputStruct = getAutoCenterRF(cellData, epochInd, channel)

%% create epoch cell array
if nargin < 3
    channel = 'Amplifier_Ch1';
end
shapeData = {};
for p = 1:length(epochInd)
    shapeData{p} = ShapeData(cellData.epochs(epochInd(p)), 'offline', channel);
end


%% Process it using standard function
ad = processShapeData(shapeData);


%% Return output to tree
analysisData = struct;

analysisData.units = '';
analysisData.type = 'combinedAcrossEpochs';
analysisData.value = ad;

outputStruct = struct;
outputStruct.analysisData = analysisData;
end
