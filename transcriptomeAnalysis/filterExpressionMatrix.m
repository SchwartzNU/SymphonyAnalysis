function [D_filter] = filterExpressionMatrix(D, floor, ceiling, allowZeros) 
% Returns a log-transformed filtered matrix with optional floor, ceiling,
%   and zeros filtered to NaN

D = log( (D*10) + 1 );
D_filter = D;

if isnumeric(floor)
    D_filter(D_filter<floor) = 0;
end

if allowZeros == 0
    D_filter(D_filter == 0) = NaN;
end

if isnumeric(ceiling)
    D_filter(D_filter>ceiling) = ceiling;
end

end