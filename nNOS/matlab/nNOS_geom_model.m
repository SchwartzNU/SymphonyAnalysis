function [allLines, connOut] = nNOS_geom_model_parameterized(theta_sd, branchN, initBranchLen)

%make soma grid
stimSize = [625 625];
subunit_RF = 100; %doesn't matter
subunit_spacing = 125;
noiseSD = 10;

[posX, posY] = makeSubunitHexGrid(stimSize, subunit_RF, subunit_spacing, noiseSD);

Ncells = length(posX);

f = figure;
ax = axes('Parent', f);axis equal;hold(ax,'on');fplot(@(x)-sqrt(300^2-x.^2),[-300 300],'color','k');fplot(@(x)sqrt(300^2-x.^2),[-300 300],'color','k');
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
   allPoints = makeCellDendrites_varbranch([posX(i),posY(i)], rand*360, [10 15], {2, 2.2}, [15 1300], 1, 1);
   
   %attempts with uniform branch numbers (old):
   %allPoints = makeCellDendrites([posX(i),posY(i)], rand*360, [200 15 10], 1000, 2, [200, 600 600], 1, 1);
   %allPoints = makeCellDendrites([posX(i),posY(i)], rand*360, [200 50 50], 1000, 3, [40, 40, 40], 1, 1);
   
   [dendLen(i), allLines{i}] = drawTree(allPoints, rand(1,3), ax);      
   %pause;
end

connectivity = ones(Ncells, Ncells)*nan;
somaDistance = ones(Ncells, Ncells)*nan;
% connPointsOut = cell(Ncells);
% connLinesOut = cell(Ncells);
connOut=[];

for i=1:Ncells
    for j=i+1:Ncells
        %connectivity(i,j) = size(intersectAllEdges(allLines{i}, allLines{j}),1);
        [connPoints,connLines] = intersectAllEdges(allLines{i}, allLines{j});
        connInd = rand(size(connPoints,1),1)<0.25;
        connPoints = connPoints(connInd,:);
        connLines = connLines(connInd,:);
        
        connectivity(i,j) = sum(connInd);
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
            connOut = cat(1,connOut,[i*ones(size(disI)) j*ones(size(disJ)) connLines disI disJ]);
            connOut = cat(1,connOut,[j*ones(size(disJ)) i*ones(size(disI)) connLines(:,2:-1:1) disJ disI]);
        end
    end    
end
C = connectivity>0;

xlim(ax,[-500 500]);
ylim(ax,[-500 500]);
figure;
scatter(somaDistance(:), connectivity(:), 'kx');
figure;
subplot(121),imagesc(C),subplot(122),plot(sum(C))


