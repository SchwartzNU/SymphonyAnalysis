function [posX, posY] = makeSubunitHexGrid(stimSize, subunit_RF, subunit_spacing, noiseSD)
if nargin < 4
    noiseSD = 0;    
end

gridSize = ceil((stimSize(1)./subunit_spacing));
if rem(gridSize,2) == 1, gridSize = gridSize+1; end

Rad3Over2 = sqrt(3) / 2;
[X, Y] = meshgrid(1:1:gridSize);
n = size(X,1);
X = Rad3Over2 * X;
Y = Y + repmat([0 0.5],[n,n/2]);

%set spacing
X = X * subunit_spacing;
Y = Y * subunit_spacing;

Ind = (X-subunit_RF*4 <= stimSize(1) & Y-subunit_RF*4 <= stimSize(2));
posX = X(Ind) - subunit_RF*2;
posY = Y(Ind) - subunit_RF*2;

if noiseSD>0
    L = length(posX);
    posX = posX + randn(L, 1) * noiseSD;
    posY = posY + randn(L, 1) * noiseSD;
end

posX = posX - mean(posX);
posY = posY - mean(posY);

posX = round(posX);
posY = round(posY);