function T = addParamForCellTypes(T, paramName, typeList, trueVal, falseVal)
ind = ismember(T.cellType, typeList);
T(ind,paramName) = {trueVal};
T(~ind,paramName) = {falseVal};