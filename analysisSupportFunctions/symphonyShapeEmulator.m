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
    runTimeSeconds = 30;
    p.spotDiameter = 30; %um
    p.searchDiameter = 250;
    p.numSpots = 10;
    p.spotTotalTime = .3;
    p.spotOnTime = .1;

    p.valueMin = .1;
    p.valueMax = 1;
    p.numValues = 1;
    p.numValueRepeats = 1;
    p.epochNum = epoch_num;
    ISOResponse = false;
    p.refineCenter = false;
    p.refineEdges = true;


    timeElapsed = currentTime - startTime;
    p.timeRemainingSeconds = runTimeSeconds - timeElapsed;

    mode = 'autoReceptiveField';
    if ISOResponse
        mode = 'isoResponse';
    end

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

    %% pause and repeat

    currentTime = currentTime + 1.0 + sd.stimTime / 1000
    pause(3)
end

