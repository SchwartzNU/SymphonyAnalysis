function strVal = makeDelimitedString(curVal)

strVal = '';
for j=1:length(curVal)
    if iscell(curVal)
        if isempty(strVal)
            strVal = num2str(curVal{j});
        else
            strVal = [strVal ', ' num2str(curVal{j})];
        end
    else
        if isempty(strVal)
            strVal = num2str(curVal(j));
        else
            strVal = [strVal ', ' num2str(curVal(j))];
        end
    end
end