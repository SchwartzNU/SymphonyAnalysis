%Adam 9/22/15, change 2/13/16


% % % definition of "maximum"
Vsort = sort(V,'descend');
Vmax = median(Vsort(1:10));
th = 0.5*Vmax;
upperTh = 0.8*Vmax;
maxInd = find(V>=upperTh);

zeroInd = find(V == 0);
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
    nextMaxima = maxInd(maxInd>=Ind(indOfInd));
    if ~isempty(nextMaxima)
        nextMax = nextMaxima(1);
    end;
    if ~isempty(nextMax)
        if isempty(nextZero) || (nextMax<nextZero) 
             susCrossInd = [susCrossInd, Ind(indOfInd)];
        end;
    end;
    %if nextMax is empty - then don't include

end;



