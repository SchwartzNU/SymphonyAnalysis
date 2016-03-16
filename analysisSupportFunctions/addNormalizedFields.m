function outputStruct = addNormalizedFields(outputStruct, fnames)
%in this struct, we are looking for arrays of values - normalize across
%nodes after percolating up.

for i=1:length(fnames)
    curField = fnames{i};
    tempField = outputStruct.(curField);
    L = length(tempField);
    vals = zeros(1,L);
    for j=1:L
        if strcmp(tempField(1).type, 'byEpoch')
            vals(j) = tempField(j).mean_c;
        elseif strcmp(tempField(1).type, 'singleValue')
            vals(j) = tempField(j).value;
        else
            disp(['Error: bad field type: ' curField]);
            return;
        end
    end
    maxVal = max(vals);
    
    newField = repmat(struct, 1, L);
    for j=1:L
        newField(j).units = 'norm.';
        newField(j).type = tempField(j).type;
        if strcmp(tempField(1).type, 'byEpoch')
            newField(j).mean_c = tempField(j).mean_c / maxVal;
            newField(j).SEM_c = tempField(j).SEM_c / maxVal;
            newField(j).SD_c = tempField(j).SD_c / maxVal;
        elseif strcmp(tempField(1).type, 'singleValue')
            newField(j).value = tempField(j).value / maxVal;
        else
            disp(['Error: bad field type: ' curField]);
            return;
        end
    end
    newName = [fnames{i} '_norm'];
    outputStruct.(newName) = newField;    
end
