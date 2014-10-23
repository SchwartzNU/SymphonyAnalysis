function test = isnan_cell(c)
if iscell(c)
    test = zeros(1,length(c));
    for i=1:length(c)
        curVal = c{i};
        if length(curVal) < 1
            test(i) = isnan(c{i});
        else
            test(i) = max(isnan(c{i}));
        end
        
    end
else
    test = isnan(c);
end