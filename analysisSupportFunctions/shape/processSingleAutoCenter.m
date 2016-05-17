% process auto center offline simply

% load('/Users/sam/analysis/cellData/051216Ac4.mat')

sessionId = 201651215217;

% epochIds = [13 14 15];

% num_epochs = length(epochIds);

epochData = cell(1);
ei = 1;
for i = 1:length(cellData.epochs)
    epoch = cellData.epochs(i);
    sid = epoch.get('sessionId');
    if sid == sessionId
        sd = ShapeData(epoch, 'offline');
        epochData{ei, 1} = sd;
        ei = 1 + ei;
    end
end

if length(epochData{1}) > 0 %#ok<ISMT>
    % analyze shapedata
    analysisData = processShapeData(epochData);
else
    disp('no epochs found');
    return
end

% figure(8);clf;
% plotShapeData(analysisData, 'spatial');

%
figure(9);clf;
plotShapeData(analysisData, 'temporalAlignment');

% figure(11);clf;
% plotShapeData(analysisData, 'subunit');

figure(10);clf;
plotShapeData(analysisData, 'plotSpatial_mean');

figure(11);clf;
plotShapeData(analysisData, 'temporalResponses');