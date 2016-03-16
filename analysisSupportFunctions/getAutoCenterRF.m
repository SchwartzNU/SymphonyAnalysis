function outputStruct = getAutoCenterRF(cellData, epochInd)

%% create epoch cell array
shapeData = {};
for p = 1:length(epochInd)
    shapeData{p} = ShapeData(cellData.epochs(epochInd(p)), 'offline');
end


%% Process it using standard function
analysisData = processShapeData(shapeData);


%% Return output to tree
outputStruct = struct;

outputStruct.analysisData.units = '';
outputStruct.analysisData.type = 'combinedAcrossEpochs';
outputStruct.analysisData.value = analysisData;

end
