function outputStruct = getAutoCenterRF(cellData, epochInd)

%% create epoch cell array
shapeData = {};
for p = 1:length(epochInd)
    shapeData{p} = ShapeData(cellData.epochs(epochInd(p)), 'offline');
end


%% Process it using standard function
outputData = processShapeData(shapeData);


%% Return output to tree
outputStruct = struct;

outputStruct.outputData.units = '';
outputStruct.outputData.type = 'combinedAcrossEpochs';
outputStruct.outputData.value = outputData;

end
