function newNodeData = vectorsToScalarMeans(nodeData)
%Adam 10/20/15 for percolateUp of vectors, in multi parameter stimuli
%See at bottom

newNodeData = struct;
fnames = fieldnames(nodeData);
for i=1:length(fnames)
    curField = fnames{i};
    if isstruct(nodeData.(curField))
        if isfield(nodeData.(curField),'type')
            newNodeData.(curField).type =  'bySplitParameter';
            newNodeData.(curField).units = nodeData.(curField).units;
            if strcmp(nodeData.(curField).type,'byEpoch')
                if strcmp(newNodeData.(curField).units,'s')
                    newNodeData.(curField).value = nodeData.(curField).median_c;
                else
                    newNodeData.(curField).value = nodeData.(curField).mean_c;
                end;
            elseif strcmp(nodeData.(curField).type,'singleValue')
                newNodeData.(curField).value = nodeData.(curField).value;
            elseif strcmp(nodeData.(curField).type,'combinedAcrossEpochs')
                newNodeData.(curField).value = [];
            end;
        end;
    end;
end;

newNodeData = getEpochResponseStats(newNodeData);   

%stuff to do after getEpochResponseStats so getEpochResponseStats doesn't see
for i=1:length(fnames)
    curField = fnames{i};
    if isstruct(nodeData.(curField))
        if isfield(nodeData.(curField),'type')
            newNodeData.(['overEpochs_',curField]) = nodeData.(curField);
        end;
    else
        newNodeData.(curField) = nodeData.(curField); %scalars such as splitParam etc. keep unchanged
    end;
end;


    




%GO FROM THIS STRUCTURE:
%        units: 'spikes'
%         type: 'byEpoch'
%            N: [4 4 4 4 4]
%         mean: [11.5000 13 14 13.2500 14]
%       median: [10 13.5000 13.5000 13 14.5000]
%           SD: [3.6968 3.1623 2.4495 1.2583 1.4142]
%          SEM: [1.8484 1.5811 1.2247 0.6292 0.7071]
%          min: [9 9 12 12 12]
%          max: [17 16 17 15 15]
%     outliers: [NaN NaN NaN NaN NaN]
%       mean_c: [11.5000 13 14 13.2500 14]
%     median_c: [10 13.5000 13.5000 13 14.5000]
%         SD_c: [3.6968 3.1623 2.4495 1.2583 1.4142]
%        SEM_c: [1.8484 1.5811 1.2247 0.6292 0.7071]
%        min_c: [9 9 12 12 12]
%        max_c: [17 16 17 15 15]


% %...TO THIS STRUCTRE BY AVERAGING (ignore numbers in example)
%        units: 'spikes'
%         type: 'byEpoch'
%        value: [17 10 9 10]
%            N: 4
%         mean: 11.5000
%       median: 10
%           SD: 3.6968
%          SEM: 1.8484
%          min: 9
%          max: 17
%     outliers: [1x0 double]
%      value_c: [17 10 9 10]
%       mean_c: 11.5000
%     median_c: 10
%         SD_c: 3.6968
%        SEM_c: 1.8484
%        min_c: 9
%        max_c: 17