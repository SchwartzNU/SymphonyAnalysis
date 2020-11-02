function [posX, posY] = linesToSegmentPositions(allLines,nseg)
Ncells = length(allLines);

posX = [];
posY = [];
z=1;
for c=1:Ncells
    curLines = allLines{c};
    for i=1:size(curLines,1)
        dx = (curLines(i,3) - curLines(i,1))/nseg;
        dy = (curLines(i,4) - curLines(i,2))/nseg;
        startX = curLines(i,1);
        startY = curLines(i,2);
        for j=1:nseg
            posX(z,:) = startX + (j-1)*dx;
            posY(z,:) = startY + (j-1)*dy;        
            z=z+1;
        end
    end    
end