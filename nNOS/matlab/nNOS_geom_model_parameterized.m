function [allLines, connOut, connectivity, nGJ, positions, distVec, allGJ_points] = nNOS_geom_model_parameterized(theta_sd, branchN, initBranchLength, GJ_density, seed)

s = RandStream('mt19937ar', 'Seed', seed);
RandStream.setGlobalStream(s);

%make soma grid
stimSize = [625 625];
centralRegionBound = 500;
subunit_RF = 100; %doesn't matter
subunit_spacing = 125;
noiseSD = 10;

[posX, posY] = makeSubunitHexGrid(stimSize, subunit_RF, subunit_spacing, noiseSD);

Ncells = length(posX);

%f = figure;
%ax = axes('Parent', f);axis equal;hold(ax,'on');fplot(@(x)-sqrt(300^2-x.^2),[-300 300],'color','k');fplot(@(x)sqrt(300^2-x.^2),[-300 300],'color','k');
ax = [];
dendLen = zeros(1<Ncells);
allLines = cell(1, Ncells);

for i=1:Ncells
   %early attempts
   %allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [10 10 15 15], {2, 1.9, 1.9}, [25 100 575], 1, 1);
   %allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [10 10 15 15], {2, 2.5, 2.5}, [25 300 975], 1, 1);
   
   %whole retina from example (zhu paper):
   % allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [10 10 15 15], {3, 5/3, 7/5}, [15 300 1000], 1, 1);
   
   %whole retina bowtie
   %allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [10 15], {2, 3}, [15 1300], 1, 1);
   
   %625um^2 sample bowtie w/ variable bowtie branching (2 or 3)
   %allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [10 15], {2, 2.2}, [15 1300], 1, 1);
   allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [theta_sd theta_sd+5], {2, branchN}, [initBranchLength 1300], 1, 1);
   
   %attempts with uniform branch numbers (old):
   %allPoints = makeCellDendrites([posX(i),posY(i)], rand*360, [200 15 10], 1000, 2, [200, 600 600], 1, 1);
   %allPoints = makeCellDendrites([posX(i),posY(i)], rand*360, [200 50 50], 1000, 3, [40, 40, 40], 1, 1);
   
   [dendLen(i), allLines{i}] = drawTree(allPoints, rand(1,3), ax, 0);      
   %pause;
end

connectivity = ones(Ncells, Ncells)*nan;
somaDistance = ones(Ncells, Ncells)*nan;
% connPointsOut = cell(Ncells);
% connLinesOut = cell(Ncells);
connOut1=[];
connOut2=[];
allGJ_points = [];

nGJ = 0;
for i=1:Ncells
    for j=i+1:Ncells
        %connectivity(i,j) = size(intersectAllEdges(allLines{i}, allLines{j}),1);
        [connPoints,connLines] = intersectAllEdges(allLines{i}, allLines{j});
        %keyboard;
        
        allGJ_points = [allGJ_points; connPoints];
        %connInd = rand(size(connPoints,1),1)<0.25
        %pause
        %connPoints = connPoints(connInd,:);
        %connLines = connLines(connInd,:);
        for c=1:size(connPoints, 1)
            if all(abs(connPoints(c,:))<centralRegionBound) % all within central region
                nGJ = nGJ + 1;
            end
        end
        connectivity(i,j) = size(connPoints, 1);
        connectivity(j,i) = connectivity(i,j);   
        
        somaDistance(i,j) = sqrt((posX(i) - posX(j))^2 + (posY(i) - posY(j))^2);
        somaDistance(j,i) = somaDistance(i,j);
        
        if ~isempty(connLines)
            %connPoints: x,y pairs of intersects
            %connLines : line indices on i,j of intersect
            lth=sqrt((allLines{i}(connLines(:,1),3)-allLines{i}(connLines(:,1),1)).^2+(allLines{i}(connLines(:,1),4)-allLines{i}(connLines(:,1),2)).^2);
            disI=sqrt((connPoints(:,1)-allLines{i}(connLines(:,1),1)).^2+(connPoints(:,2)-allLines{i}(connLines(:,1),2)).^2)./lth;
            lth=sqrt((allLines{j}(connLines(:,2),3)-allLines{j}(connLines(:,2),1)).^2+(allLines{j}(connLines(:,2),4)-allLines{j}(connLines(:,2),2)).^2);
            disJ=sqrt((connPoints(:,1)-allLines{j}(connLines(:,2),1)).^2+(connPoints(:,2)-allLines{j}(connLines(:,2),2)).^2)./lth;
            connOut1 = cat(1,connOut1,[i*ones(size(disI)) j*ones(size(disJ)) connLines disI disJ]);
            connOut2 = cat(1,connOut2,[j*ones(size(disJ)) i*ones(size(disI)) connLines(:,2:-1:1) disJ disI]);
        end
    end    
end
%nGJ
L = size(connOut1,1); %total number of crossings

crossingDensity = nGJ ./ (centralRegionBound * 1E-3)^2; %crossings per square mm
fraction_GJ = GJ_density ./ crossingDensity;

if fraction_GJ > 1
    disp('Error: too few crossings in network for desired density');
    ind = ones(L,1);
else
    ind = rand(L,1) < fraction_GJ;    
end
connOut = [connOut1, connOut2];
connOut = connOut(ind,:);
connOut = reshape(connOut,[size(connOut,1)*2, size(connOut,2)/2]);
connOut = connOut(:,[1 4 2 5 3 6]);

allGJ_points = allGJ_points(ind, :);

%xlim(ax,[-1000 1000]);
%ylim(ax,[-1000 1000]);

% figure;
% scatter(somaDistance(:), connectivity(:), 'kx');
% figure;
% subplot(121),imagesc(C),subplot(122),plot(sum(C))
positions = [posX, posY];
L = length(positions);
distVec = zeros(1,L);
targetInd = 21;
for i=1:L
    distVec(i) = sqrt((positions(i,1) - positions(targetInd,1))^2 +  (positions(i,2) - positions(targetInd,2))^2);
end

