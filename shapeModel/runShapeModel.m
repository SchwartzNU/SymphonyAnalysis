%% SHAPE MODEL
% Sam Cooler 2016

disp('Running full simulation');

% cellName = '060716Ac2';
% acName = '348';

% cellName = '060216Ac2'; % original good WFDS
% acName = '1032';

cellName = '033116Ac2';
acName = '263';


% on alpha
% cellName = '051216Ac9';
% acName = '933';

% imgDisplay = @(X,Y,d) imagesc(X,Y,flipud(d'));
% imgDisplay2 = @(mapX, mapY, d) (surface(mapX, mapY, zeros(size(mapY)), d), grid off);
normg = @(a) ((a+eps) / max(abs(a(:))+eps));
plotGrid = @(row, col, numcols) ((row - 1) * numcols + col);


plotSpatialGraphs = 1;
plotStimulus = 0;
plotSubunitCurrents = 0;
plotOutputCurrents = 1;
plotCellResponses = 1;
plotOutputNonlinearity = 0;
plotResultsByOptions = 0;

runInParallelPool = 1;

saveOutputSignalsToHDF5 = 0;
outputHDF5Name = sprintf('shapeModelOutput_%s.h5', cellName);
outputStruct = struct();

%% Setup
shapeModelSetup

%% Run simulation
shapeModelStimAndSim

%% Rescale currents and combine, then extract parameters
shapeModelAnalyzeOutput

%% Save HDF5 file
delete(outputHDF5Name);
exportStructToHDF5(outputStruct, outputHDF5Name, '/');