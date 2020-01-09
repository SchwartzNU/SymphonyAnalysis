function curNode = mergeIntoNode(curNode, outputStruct)

fnames = fieldnames(outputStruct);
for i=1:length(fnames)
    curField = fnames{i};
    
    %merge the whole thing
    curNode.(curField) = outputStruct.(curField);

    %extract out just summary stats;
    if strcmp(outputStruct.(curField).type, 'byEpoch')
       if strcmp(outputStruct.(curField).units, 's') %for times, take the median instead of the mean
           curNode.([curField '_median']) = outputStruct.(curField).median_c;           
       else
           curNode.([curField '_mean']) = outputStruct.(curField).mean_c;
       end
    elseif strcmp(outputStruct.(curField).type, 'singleValue')
       curNode.([curField '_value']) = outputStruct.(curField).value;
    end
end
