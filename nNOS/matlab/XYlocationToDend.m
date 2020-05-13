function [cellInd, dendInd, segFraction] = XYlocationToDend(posX, posY, allLines, nseg, x, y)

Npoints = length(x);
cellInd = zeros(Npoints,1);
dendInd = zeros(Npoints,1);
segFraction = zeros(Npoints,1);

Ncells = length(allLines);


for j=1:Npoints
    D = sqrt((posX - x(j)).^2 + (posY - y(j)).^2);
    [~, vecInd] = min(D);
    
    z=1;
    for c=1:Ncells
        curLines = allLines{c};
        for i=1:size(curLines,1) % for each dendrite
            if z < vecInd && z+nseg >= vecInd 
                cellInd(j) = c-1;
                dendInd(j) = i-1;
                segFraction(j) = (vecInd-z)/nseg;  
                z=z+nseg;
            else
                z=z+nseg;
            end
        end
    end
end