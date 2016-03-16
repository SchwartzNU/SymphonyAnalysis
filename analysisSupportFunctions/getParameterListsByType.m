function [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode)
byEpochParamList = {};
singleValParamList = {};
collectedParamList = {};

fnames = fieldnames(curNode);
for i=1:length(fnames)
    curField = fnames{i};
    if isstruct(curNode.(curField))
       if strcmp(curNode.(curField).type, 'byEpoch')
           byEpochParamList = [byEpochParamList curField];      
       elseif strcmp(curNode.(curField).type, 'singleValue')
           singleValParamList = [singleValParamList curField];
       elseif strcmp(curNode.(curField).type, 'combinedAcrossEpochs')
           collectedParamList = [collectedParamList curField];
       end
    end
end