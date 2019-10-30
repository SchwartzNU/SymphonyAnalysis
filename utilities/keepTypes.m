function T = keepTypes(T, typeList)
ind = ismember(T.cellType, typeList);
T = T(ind,:);