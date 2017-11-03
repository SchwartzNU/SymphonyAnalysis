function [D_withExclusions, cellInd_withExclusions, cellTypes_withExclusions, directionPref_withExclusions] = excludeSubset(D, cellTypes, selection, directionPref)

% Accepts:
%   selection: either a string or a vector of strings (note, vector of
%       strings must be ["x","y"], not single quotes)

% Returns: 
%   targetInd: a vector of cell indices within vector 'cellTypes' that 
%       exclude the string(s) provided in selection.
%   D_withExclusions: Expression Matrix without those cells - remember to
%       refer to those indices when working with this.

cellInd_withExclusions = find(not(contains(cellTypes, selection)));
D_withExclusions = D(1:end,cellInd_withExclusions);
cellTypes_withExclusions = cellTypes(cellInd_withExclusions);
directionPref_withExclusions = directionPref(cellInd_withExclusions);

end