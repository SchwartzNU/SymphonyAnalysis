function outputStruct = getAutoCenterRF(cellData, epochInd)

%% create epoch cell array
epochData = {};
for p = 1:length(epochInd)
    epochData{p} = extractShapeDataFromEpoch(cellData.epochs(epochInd(p)), 'offline');
end


%% Process it using standard function
outputData = processShapeData(epochData);


%% Return output to tree
outputStruct = struct;

outputStruct.outputData.units = '';
outputStruct.outputData.type = 'combinedAcrossEpochs';
outputStruct.outputData.value = outputData;

end
