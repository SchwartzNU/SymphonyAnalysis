%% SHAPE MODEL
% Sam Cooler 2016

% cellName = '060716Ac2';
% acName = '348';

cellName = '060216Ac2'; % original good WFDS
acName = '1032';


% cellName = '033116Ac2'; % nice RF with edges and bars, but missing bars spikes and inhibitory temporal align
% acName = '263';


% on alpha
% cellName = '051216Ac9';
% acName = '933';



useRealRf = 0;
useRealFilters = 0;
useStimulusFilter = 0;
useSubunits = 0;
useOffFilters = 0;
useInhibition = 1;

plotSpatialGraphs = 1;
plotStimulus = 0;
plotStimulusFramesOverParameterSets = 0;
plotSubunitCurrents = 0;
plotOutputCurrents = 1;
plotCellResponses = 1;
plotOutputNonlinearity = 0;
plotResultsByOptions = 0;

runInParallelPool = 0;

saveOutputSignalsToHDF5 = 0;
outputHDF5Name = sprintf('shapeModelOutput_%s.h5', cellName);
outputStruct = struct();

% imgDisplay = @(X,Y,d) imagesc(X,Y,flipud(d'));
% imgDisplay2 = @(mapX, mapY, d) (surface(mapX, mapY, zeros(size(mapY)), d), grid off);
normg = @(a) ((a+eps) / max(abs(a(:))+eps));
plotGrid = @(row, col, numcols) ((row - 1) * numcols + col);
calcDsi = @(angles, values) abs(sum(exp(sqrt(-1) * angles) .* values) / sum(values));


if ~exist('loadedCellName', 'var') || ~strcmp(loadedCellName, cellName) || ~strcmp(loadedAcName, acName)
    disp('Loading cell filters and responses')
%     extractMovingBarResponses
    loadedCellName = cellName;
    loadedAcName = acName;

    if useRealFilters
        extractFilters
    end
end



%% Big parameter loop around overall parameters

disp('Running full simulation');


% paramColumnNames = {'barSpeeds', 'angle'};
paramColumnsNames = {'edge polarity','angle'};
col_edgeFlip = 1;
col_edgeAngle = 2;
%'spatial offset', 'ex delay', };
% col_rfOffset = 1;
% col_barSpeed = 1;
% col_filterDelay = 1;

% paramValues  = {0;
%                 10;
%                 50};

% paramValues  = {195;
%                 585;
%                 975;
%                 1365};

% paramValues = [250; 500; 1000; 2000];
            

% paramValues = [.1, 20];

% paramValues = [0;
%                2;
% %                8;
%                16;
% %                24;
%                35;
%                52;
%                75];
            

% paramValues = [.04; 
%                .05;
%                .06;
%                .07;
%                .08];

           
% p1 = [.04,.07,.1];
% p2 = [2,12,32];
% 
paramValues = [0, 0]; 

% paramValues = [0, 0
%                1, 0
%                0, 90
%                1, 90];

% 
% for i1 = 1:length(p1)
%     for i2 = 1:length(p2)
%         paramValues(end+1,1:2) = [p1(i1),p2(i2)];
%     end
% end

[numParamSets,numParams] = size(paramValues);

dsiByParamSet = [];
valuesByParamSet = [];

tic

for paramSetIndex = 1:numParamSets
    fprintf('Param Set %d: %s\n', paramSetIndex, mat2str(paramValues(paramSetIndex,:)));
    
    %% Setup

    shapeModelParameterSetup
    
    if ~useRealFilters
       shapeModelParameterizedFilters 
    end
    
    shapeModelSubunitSetup
    
    shapeModelStimSetup
    
    if useStimulusFilter
        shapeModelStimulusFilter
    end
    
    if plotStimulusFramesOverParameterSets
        shapeModelPlotStimFrames
    end

    %% Run simulation
    shapeModelSim

    %% Rescale currents and combine, then extract parameters
    shapeModelAnalyzeOutput

end

disp('Model run complete')
toc

%% display DSI over parameters
if numParamSets >= 3
    figure(901);clf;
    
    if numParams == 1
%         d1 = linspace(min(paramValues(:,1)), max(paramValues(:,1)), 10);
%         m = interp1(paramValues(:,1), dsiByParamSet, d1);
%         plot(d1, m)
        
        plot(paramValues(:, col_barSpeed), dsiByParamSet)

        %% Plot WFDS cells
%         hold on
%         plot(abs(dtab{selectWfdsOn,'spatial_exin_offset'}), dtab{selectWfdsOn,'best_DSI_sp'}, '.', 'MarkerSize', 20)
%         plot(abs(dtab{selectWfdsOff,'spatial_exin_offset'}), dtab{selectWfdsOff,'best_DSI_sp'}, '.', 'MarkerSize', 20)
%         plot(abs(dtab{selectControl,'spatial_exin_offset'}), dtab{selectControl,'best_DSI_sp'}, '.', 'MarkerSize', 20)
%         hold off
        legend('Model','WFDS ON','WFDS OFF','Control')
        xlabel(paramColumnNames{1})
        ylabel('DSI')
        
    elseif numParams == 2
        d1 = linspace(min(paramValues(:,1)), max(paramValues(:,1)), 10);
        d2 = linspace(min(paramValues(:,2)), max(paramValues(:,2)), 10);

        [d1q,d2q] = meshgrid(d1, d2);        
        c = griddata(paramValues(:,1), paramValues(:,2), dsiByParamSet, d1q, d2q);
        surface(d1q, d2q, zeros(size(d1q)), c)
        hold on
%         plot(paramValues(:,1), paramValues(:,2), '.', 'MarkerSize', 40)
        hold off
        xlabel(paramColumnNames{1})
        ylabel(paramColumnNames{2})
        colorbar
    end
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