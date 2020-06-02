function [] = makeSpotStimFiles(locRange, nPoints, radius, posX, posY, allLines, nseg)
rootdir = '/Users/gregoryschwartz/Dropbox/nNOS-2 paper/Model/SpotStimLoop_20um';
%same for X and Y since network is square
[X, Y] = meshgrid(locRange(1)-100:1:locRange(2)+100);
locVals = round(linspace(locRange(1), locRange(2), nPoints));
for x=locVals
    x
    for y=locVals        
        y
        tic;
        D = sqrt((X-x).^2 + (Y-y).^2);
        inInd = D<=radius;
        %keyboard;
        [cellInd, dendInd, segFraction] = XYlocationToDend(posX, posY, allLines, nseg, X(inInd), Y(inInd));
        M = [cellInd, dendInd, segFraction];
        M = unique(M, 'rows');
        dlmwrite([rootdir filesep 'x' num2str(x) 'y' num2str(y) '.txt'], M, '\t');
        toc;
    end
end
