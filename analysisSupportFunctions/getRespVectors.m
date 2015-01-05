function allRespVals = getRespVectors(rootData, respFields)
%returns a single vector (if only one resp field) or a cell array of them
if length(respFields) > 1
    returnCell = true;
else
    returnCell = false;
end

nFields = length(respFields);
allRespVals = cell(1,nFields);

for i=1:nFields
    curField = respFields{i};
    if strcmp(rootData.(curField).type, 'byEpoch');
        if strcmp(rootData.(curField).units, 's');
            respVals = rootData.(curField).median_c;
        else
            respVals = rootData.(curField).mean_c;
        end
    elseif strcmp(rootData.(curField).type, 'singleValue');
        respVals = rootData.(curField).value;
    else
        respVals = [];
    end
    allRespVals{i} = respVals;
end

if ~returnCell
    allRespVals = allRespVals{1};
end