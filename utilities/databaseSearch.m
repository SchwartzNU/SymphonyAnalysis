function [locations, values] = databaseSearch(database, pattern, parentName, locations, values)

if nargin < 3
    parentName = '';
    locations = {};
    values = {};
end

if isstruct(database)
    for s = 1:length(database)
        fieldNames = fieldnames(database(s));
        fieldArray = struct2cell(database(s));
        for c = 1:length(fieldNames)
            childName = [parentName, '(', num2str(s) , ').', fieldNames{c}, ];
            [locations, values] = databaseSearch(fieldArray{c}, pattern, childName, locations, values);    
        end
    end
    
elseif iscell(database)
    database = reshape(database, 1, []);
    for c = 1:length(database)
        childName = [parentName, '{', num2str(c) , '}'];
        [locations, values] = databaseSearch(database{c}, pattern, childName, locations, values);    
    end
    
elseif isnumeric(database)
    database = num2str(database);
    [locations, values] = databaseSearch(database, pattern, parentName, locations, values);
    
elseif isstring(database) || ischar(database)
    contents = cellstr(database);
    if any(contains(contents, pattern))
        ind = length(locations) + 1;
        locations{ind} = parentName;
        values{ind} = database;
    end
end    

end