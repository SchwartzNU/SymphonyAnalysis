function v = evalsToNumeric(s)
    %returns true if string s will evaluate toa numeric value (scalar or
    %matrix)
    v = all(isstrprop(s, 'punct') | isstrprop(s, 'digit') | isstrprop(s, 'wspace'));
    
