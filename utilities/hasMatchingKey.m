function [v, keyName] = hasMatchingKey(M, keyName)
allKeys = M.keys;
ind = find(strcmp(keyName, allKeys));
if isempty(ind) %look for inexact match
    keyName = strtok(keyName, '_');
    ind = find(strcmp(keyName, allKeys));
end    
v = ~isempty(ind);

if v
    keyName = allKeys{ind};
else
    keyName = '';
end