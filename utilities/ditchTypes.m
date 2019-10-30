function T = ditchTypes(T, typeList)
ind = ismember(T.cellType, typeList);
T = T(~ind,:);