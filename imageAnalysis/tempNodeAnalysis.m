function tempNodeAnalysis(S)

Nedges = length(S.edges);

allD = {};
allAngles = {};

z=1;
segmentInd = 1;
for i=1:Nedges
    a = S.edges(i,2);
    b = S.edges(i,1);
    %check for continuity
    if b-a == 1
        D(z) =  sqrt((S.allXYpos(a,1) - S.allXYpos(b,1)).^2 + (S.allXYpos(a,2) - S.allXYpos(b,2)).^2 + (S.allZpos(a) - S.allZpos(b)).^2);
        p1 = [S.allXYpos(a,1) S.allXYpos(a,1) S.allZpos(a)];
        p2 = [S.allXYpos(b,1) S.allXYpos(b,1) S.allZpos(b)];
        if z>1        
            %angles(z) = atan2(norm(cross(p0,p1)), dot(p0,p1)) - atan2(norm(cross(p1,p2)), dot(p1,p2));
            angles(z) = acos(dot(p1, p2) / (norm(p1) * norm(p2)));
            deltaZ(z) = abs(p1(3) - p2(3));
            deltaXY(z) = sqrt((S.allXYpos(a,1) - S.allXYpos(b,1)).^2 + (S.allXYpos(a,2) - S.allXYpos(b,2)).^2);
        end
        z=z+1;
        p0 = p1;
    else %reset
        allD{segmentInd} = D;
        allAngles{segmentInd} = angles;
        allXY{segmentInd} = deltaXY;
        allZ{segmentInd} = deltaZ;
        p0 = [];
        p1 = [];
        D = [];
        angles = []; angles(1) = 0;
        deltaZ = []; deltaZ(1) = 0;
        deltaXY = []; deltaXY(1) = 0;
        z = 1;
        segmentInd = segmentInd + 1;
    end
end

allD_cs_flat = [];
allCos_cs_flat = [];
allXY_cs_flat = [];
allZ_cs_flat = [];
for i=1:length(allD)
    allD_cs_flat = [allD_cs_flat cumsum(allD{i})];
    allCos_cs_flat = [allCos_cs_flat cos(cumsum(allAngles{i}))];   
    allXY_cs_flat = [allXY_cs_flat cumsum(allXY{i})];
    allZ_cs_flat = [allZ_cs_flat cumsum(allZ{i})];
end

allR_cs_flat = allXY_cs_flat./allZ_cs_flat;

[Dvals, ind] = histc(allD_cs_flat, [0 prctile(allD_cs_flat,1:99)]);
cosVals = zeros(1, length(Dvals));
for i=1:length(cosVals)
    DvalsMean(i) = mean(allD_cs_flat(ind==i));
    curVals = allCos_cs_flat(ind==i);
    cosValsMean(i) = mean(real(curVals));
    cosValsErr(i) = std(real(curVals))./sqrt(length(curVals));
   
    curVals = allXY_cs_flat(ind==i);
    dXYMean(i) = mean(real(curVals));
    dXYErr(i) = std(real(curVals))./sqrt(length(curVals));
    
    curVals = allZ_cs_flat(ind==i);
    dZMean(i) = mean(real(curVals));
    dZErr(i) = std(real(curVals))./sqrt(length(curVals));
    
    curVals = allR_cs_flat(ind==i);
    RMean(i) = mean(real(curVals));
    RErr(i) = std(real(curVals))./sqrt(length(curVals));
end

