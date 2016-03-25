function outputStruct = getAutoCenterRF(cellData, epochInd)

%% create epoch cell array
shapeData = {};
for p = 1:length(epochInd)
    shapeData{p} = ShapeData(cellData.epochs(epochInd(p)), 'offline');
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
