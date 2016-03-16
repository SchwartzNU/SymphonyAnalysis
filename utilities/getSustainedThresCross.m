function susCrossInd = getSustainedThresCross(V,th)
%Adam 9/22/15




[MaxV, MaxVind] = max(V);
zeroInd = find(V == 0);
maxInd = find(V == MaxV);
susCrossInd = [];


Vorig = V(1:end-1);
Vshift = V(2:end);

Ind = find(Vorig<th & Vshift>=th) + 1;
for indOfInd = 1:length(Ind)
    %look for crossings upwards, where the maximum arrives sooner than a
    %zero, AFTER crossing point.
    nextZero = []; nextMax = [];
    nextZeros = zeroInd(zeroInd>Ind(indOfInd));
    if ~isempty(nextZeros)
        nextZero = nextZeros(1);
    end;
    nextMaxima = maxInd(maxInd>Ind(indOfInd));
    if ~isempty(nextMaxima)
        nextMax = nextMaxima(1);
    end;
    if ~isempty(nextMax)
        if isempty(nextZero) || (nextMax<nextZero) 
             susCrossInd = [susCrossInd, Ind(indOfInd)];
        end;
    end;
    %if nextMax is empty - then don't include,
    %unless it's the case below

end;
%If no such crossing was found, then the only crossings found are also maxima
%Commenting this out is an option, which will give more NaNs but maybe fewer outliers
if isempty(susCrossInd) 
    susCrossInd = MaxVind;
end;


