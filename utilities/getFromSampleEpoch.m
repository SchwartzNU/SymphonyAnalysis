function nodeData = getFromSampleEpoch(cellData, nodeData, params)
    L = length(params);
    SampleEpoch = cellData.epochs(nodeData.epochID(1));
    for i=1:L
       val = SampleEpoch.get(params{i});
       if ~isnan(val)
           nodeData.(params{i}) = val;
       end
    end
end