%% Initialize changing parameters
currentTime = 0;
startTime = 0;
epoch_num = 0;

analysisData = [];
epochData = {};
continueRun = true;

%% Loop

while continueRun

    %% setup fixed params as in autocenter
    epoch_num = epoch_num + 1;

    p = struct();
    runTimeSeconds = 300;
    p.spotDiameter = 30; %um
    p.searchDiameter = 350;
    p.numSpots = 20;
    p.spotTotalTime = .3;
    p.spotOnTime = .1;

    p.valueMin = .1;
    p.valueMax = .5;
    p.numValues = 2;
    p.numValueRepeats = 3;
    p.epochNum = epoch_num;
    ISOResponse = false;
    p.refineCenter = false;
    p.refineEdges = true;
    
    p.generatePositions = true;

    mode = 'receptiveField';
    if ISOResponse
        mode = 'isoResponse';
    end    
    
    if true
        imode = input('stimulus mode? ','s');
        if strcmp(imode, 'curves') % response curves
            mode = 'receptiveField';
            p.numSpots = input('num positions? ');
            p.generatePositions = false;
            p.numValues = input('num values? ');
            p.numValueRepeats = input('num value repeats? ');

        elseif strcmp(imode, 'map')
            mode = 'receptiveField';
            p.generatePositions = input('generate new positions? ');

        elseif strcmp(imode, 'align')
            mode = 'temporalAlignment';

        elseif strcmp(imode, 'rv')
            mode = 'refineVariance';
            p.variancePercentile = input('percentile of highest variance to refine (0-100)? ');
            p.numValueRepeats = input('num value repeats to add? ');
            
        elseif strcmp(imode, 'iso')
            mode = 'isoResponse';
            
        end
    end    

    timeElapsed = currentTime - startTime;
    p.timeRemainingSeconds = runTimeSeconds - timeElapsed;


    %% generate stimulus

    runConfig = generateShapeStimulus(mode, p, analysisData);
    continueRun = runConfig.autoContinueRun;

    %% Create fake epoch

    epoch = FakeEpoch(p, runConfig);

    %% create shapedata

    sd = ShapeData(epoch, 'offline');

    %% simulate spike responses

    sd.simulateSpikes();
    epochData{epoch_num, 1} = sd;

    %% analyze shapedata
    analysisData = processShapeData(epochData);

    figure(8);clf;
    plotShapeData(analysisData, 'spatial');

    figure(9);clf;
    plotShapeData(analysisData, 'temporalAlignment');

    figure(10);clf;
    plotShapeData(analysisData, 'subunit');

%     figure(11);clf;
%     plotShapeData(analysisData, '');
    %% pause and repeat

    currentTime = currentTime + 1.0 + sd.stimTime / 1000
%     pause(3)
end

