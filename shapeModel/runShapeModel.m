%% SHAPE MODEL
% Sam Cooler 2016

% cellName = '060716Ac2';
% acName = '348';

cellName = '060216Ac2'; % original good WFDS
acName = '1032';

useRealRf = 0;
useRealFilters = 0;
useSubunits = 0;

% cellName = '033116Ac2'; % nice RF with edges and bars, but missing bars spikes and inhibitory temporal align
% acName = '263';


% on alpha
% cellName = '051216Ac9';
% acName = '933';

% imgDisplay = @(X,Y,d) imagesc(X,Y,flipud(d'));
% imgDisplay2 = @(mapX, mapY, d) (surface(mapX, mapY, zeros(size(mapY)), d), grid off);
normg = @(a) ((a+eps) / max(abs(a(:))+eps));
plotGrid = @(row, col, numcols) ((row - 1) * numcols + col);
calcDsi = @(angles, values) abs(sum(exp(sqrt(-1) * angles) .* values) / sum(values));


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


if ~exist('loadedCellName', 'var') || ~strcmp(loadedCellName, cellName) || ~strcmp(loadedAcName, acName)
    disp('Loading cell filters and responses')
%     extractMovingBarResponses
    loadedCellName = cellName;
    loadedAcName = acName;

    if useRealFilters
        extractFilters
    end
end



%%
disp('Running full simulation');


%% Big parameter loop around 12 angles and simulation core

paramColumnNames = {'positionOffset'};
col_positionOffset = 1;
col_barSpeed = 1;

% paramValues  = {0;
%                 10;
%                 50};

% paramValues  = {195;
%                 585;
%                 975;
%                 1365};
            
paramValues = {1000}; % barspeed
            
            
[numParamSets,numParams] = size(paramValues);

dsiByParamSet = [];
valuesByParamSet = [];



for paramSetIndex = 1:numParamSets
    fprintf('Param Set %d: %s\n', paramSetIndex, num2str(paramValues{paramSetIndex,:}));
    
    %% Setup

    shapeModelParameterSetup
    
    if ~useRealFilters
       shapeModelParameterizedFilters 
    end    
    
    shapeModelSubunitSetup
    
    shapeModelStimSetup

    %% Run simulation
    shapeModelSim

    %% Rescale currents and combine, then extract parameters
    shapeModelAnalyzeOutput

end

%% process output nonlinearity

% speeds = cell2mat(paramValues)';
% anglesRads = deg2rad(stim_barDirections);
% 
% inputs = [0,20.5,30];
% outputs = [0,7,45];
% 
% 
% figure(97)
% plot(inputs, outputs)
% 
% for ps = 1:numParamSets
%     lin = valuesByParamSet(ps,:);
%     
%     nonlin = interp1(inputs, outputs, lin);
%     nonlinValuesByParamSet(ps,:) = nonlin;
%     nonlinDsiByParamSet(ps,1) = calcDsi(anglesRads, nonlin);
% end
% 
% 
% figure(110);
% clf;
% ha = tight_subplot(1,2,.1,.1);
% for ps = 1:numParamSets
%     axes(ha(1))
%     polar(anglesRads,valuesByParamSet(ps,:))
%     hold on
%     % ylim([0,max(valuesByParamSet(:))+2])
%     
%     axes(ha(2))
%     vals = nonlinValuesByParamSet(ps,:);
%     polar(anglesRads, vals./max(vals))
%     hold on
%     % ylim([0,max(nonlinValuesByParamSet(:))+2])
% end
% axes(ha(1))
% legend('195','585','975','1365','Location','best');
% % ylim([0,max(valuesByParamSet(:))+2])
% title('before nonlin')    
% 
% 
% axes(ha(2))
% title('after nonlin')
% legend('195','585','975','1365','Location','best');  
% 
% 
% sanes = [0.2
% 0.35
% 0.12
% 0.05];
% 
% figure(111);clf;
% plot(cell2mat(paramValues)', sanes);
% hold on
% plot(cell2mat(paramValues)', dsiByParamSet);
% plot(cell2mat(paramValues)', nonlinDsiByParamSet);
% 
% legend('sanes','model','modelNonlin')
% hold off

%% Save HDF5 file
if saveOutputSignalsToHDF5
    delete(outputHDF5Name);
    exportStructToHDF5(outputStruct, outputHDF5Name, '/');
end