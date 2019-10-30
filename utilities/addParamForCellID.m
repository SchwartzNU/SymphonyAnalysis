function T = addParamForCellID(T, paramName, typeList, trueVal, falseVal)


    ind = ismember(T.cellName, typeList);
    T(ind,paramName) = {trueVal};
    T(~ind,paramName) = {falseVal};
end
