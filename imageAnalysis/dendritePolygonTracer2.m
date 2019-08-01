
dbFileName = '~/Google Drive/research/retina/datasets/dendritePolygonDatabase.mat';
if exist(dbFileName, 'file')
    load(dbFileName)
    fprintf('Loaded %g cells from db\n', size(dendritePolygonDatabase, 1));
else
    dendritePolygonDatabase = table();
    disp('Created new db')
end


[fname, pathname] = uigetfile('*', 'Select image file');
disp(fname);
[startIndex,endIndex] = regexp(fname,'[0-9]{6}[AB]c[0-9]+');
cellNameGuess = fname(startIndex:endIndex);
cellName = input(sprintf('cell name: [%s]', cellNameGuess),'s');
if strcmp(cellName, '')
    cellName = cellNameGuess;
end
cellType = input('cell type (FmON 1 FmOFF 2): [2]','s');
if strcmp(cellType, '')
    cellType = 2;
else
    cellType = str2double(cellType);
end

cellType

M = imread([pathname, fname]);

figure(19);clf;
s = size(M);
% image([-s(1), s(1)]/2, [-s(2), s(2)]/2, flipud(M));
imshow(flipud(M))
set(gca,'YDir','normal');
% colormap('gray');
disp('Double click on the soma.');
[x_soma, y_soma] = getpts(gcf);
x_soma = x_soma(end);
y_soma = y_soma(end); %double click ends, so keep the last one
% draw soma
rectangle('Position',20 * [-.5, -.5, 1, 1] + [x_soma, y_soma, 0, 0],'Curvature',1, 'FaceColor', [1 .3 0]);


disp('Click on dendrite tips. Double click to finish.');
[xpts, ypts] = getpts(gcf);
dendriticPolygon = cat(2,xpts,ypts); %make polygon of the dendritic tree

drawPolygon(dendriticPolygon(:,1), dendriticPolygon(:,2), 'b', 'LineWidth',2);

dendritePolygonDatabase(cellName,{'soma','polygon','fname','cellType'}) = {[x_soma, y_soma], dendriticPolygon, fname, cellType};

legend('Outline')

%Eccentricity
%Ecc = sqrt(1 - (Min^2/Maj^2));
%hold on
%drawLine(Maj_axis,'Color','k');
%drawLine(Min_axis(I_min,:),'Color','k');

saveDecision = input(sprintf('[Enter] to save %s in db, or control-C to abort', cellName),'s');
if strcmp(saveDecision,'')
    save('dendritePolygonDatabase.mat','dendritePolygonDatabase')
    disp('saved')
else
    disp('not saved')
end

