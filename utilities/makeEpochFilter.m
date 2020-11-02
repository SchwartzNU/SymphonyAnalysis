function epochFilter = makeEpochFilter(D, patternString)
epochFilter = SearchQuery();

for i=1:size(D,1)
    if ~isempty(D{i,1})
        epochFilter.fieldnames{i} = D{i,1};
        epochFilter.operators{i} = D{i,2};
        value_str = D{i,3};
        if isempty(value_str)
            value = [];
        elseif strfind(value_str, ',')
            z = 1;
            r = value_str;
            while ~isempty(r)
                [token, r] = strtok(r, ',');
                value{z} = strtrim(token);
                z=z+1;
            end
        else
            value = str2num(value_str); %#ok<ST2NM>
        end
        if ~isempty(value)
            epochFilter.values{i} = value;
        else
            epochFilter.values{i} = value_str;
        end
    end
end

epochFilter.pattern = patternString;