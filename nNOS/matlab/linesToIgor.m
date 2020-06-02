function [] = linesToIgor(allLines)
Ncells = length(allLines);

Xmat = [];
Ymat = [];
z=1;
for c=1:Ncells
    curLines = allLines{c};
    for i=1:size(curLines,1)
        Xmat(z,:) = [curLines(i,1) curLines(i,3)];
        Ymat(z,:) = [curLines(i,2) curLines(i,4)];        
        z=z+1;
    end    
end
dlmwrite('allLines_X.txt', Xmat');
dlmwrite('allLines_Y.txt', Ymat');
