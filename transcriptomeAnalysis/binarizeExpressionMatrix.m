function [D_binary] = binarizeExpressionMatrix(D, absentMax, presentMin, doLog)


if doLog
    D = log(D * 1000 + 1);
    absentMax = log(absentMax * 1000 + 1);
    presentMin = log(presentMin * 1000 + 1);
end

D_binary = D;

D_binary(D > presentMin) = presentMin;
D_binary(D < presentMin) = absentMax;
D_binary(D < absentMax) = 0;

D_binary(D_binary > 0) = 1;
end