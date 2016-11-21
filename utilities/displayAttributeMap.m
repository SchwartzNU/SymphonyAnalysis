function [] = displayAttributeMap(M)

allKeys = M.keys;
L = length(allKeys);
keyLen = zeros(1,L);
for i=1:L
    keyLen(i) = length(allKeys{i});
end
maxLen = max(keyLen);

disp(sprintf('\n'));
for i=1:L    
    whiteSpace = 5 + maxLen - keyLen(i);    
    val = M(allKeys{i});
    val = reshape(val, 1, []);
    if iscellstr(val)
       val = [val{:}];
    end
    disp([allKeys{i} ':' repmat(' ', 1, whiteSpace) num2str(val)]);
end
disp(sprintf('\n'));