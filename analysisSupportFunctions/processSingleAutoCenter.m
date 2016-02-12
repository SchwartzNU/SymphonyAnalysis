% process auto center offline simply

load('/Users/sam/analysis/cellData/020516Ac3.mat')
epochIds = [13 14 15];

num_epochs = length(epochIds);

epochData = cell(1);
for i = 1:num_epochs
    epoch = cellData.epochs(epochIds(i));
    sd = ShapeData(epoch, 'offline');
    epochData{i, 1} = sd;
end
    
% analyze shapedata
analysisData = processShapeData(epochData);

% figure(8);clf;
% plotShapeData(analysisData, 'spatial');

%%
% figure(9);clf;
% plotShapeData(analysisData, 'temporalAlignment');
% 
% figure(11);clf;
% plotShapeData(analysisData, 'subunit');

figure(10);clf;
plotShapeData(analysisData, 'wholeCell');