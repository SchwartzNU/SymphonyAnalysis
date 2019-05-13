function [compEpochs, compData] = doCacapacitanceCompensation(cellData, fileName, controlDS, DStoComp, saveFlag)
%This function will take in a cell and associated datasets to compensate
%and compensate for them
% written by Sophia 4/15/19

%%% error: curerntly there exists one epoch where the overcompensation is
%%% huge, possibly broken epoch, double check data set and run again
global CELL_DATA_FOLDER
capLen = 300;

%%% generate TTX (control) capacitance traces
cEpochs = cellData.savedDataSets(controlDS);
cpulse1Curr = zeros(length(cEpochs), 1);
c_v0Tov1Cap = zeros(length(cEpochs), capLen);
c_v1Tov2Cap = zeros(length(cEpochs), capLen);
c_v2Tov3Cap = zeros(length(cEpochs), capLen);
for cei = 1:length(cEpochs)
    e = cellData.epochs(cEpochs(cei));
    d = e.getData();
    cpulse1Curr(cei) = e.get('pulse1Curr');
    if cei == 1
        sampR = e.get('sampleRate');
        preT = e.get('preTime');
        stim1T = e.get('stim1Time');
        stim2T = e.get('stim2Time');
        tailT = e.get('tailTime');
        stim1Start = preT*sampR/1000;
        stim2Start = (preT+stim1T)*sampR/1000;
        stimEnd = (preT+stim1T+stim2T)*sampR/1000;
    end
    c_v0Tov1Cap(cei, :) = d(stim1Start+1:stim1Start+capLen) - d(stim1Start+capLen);
    c_v1Tov2Cap(cei, :) = d(stim2Start+1:stim2Start+capLen) - d(stim2Start+capLen);
    v2Tov3Cap = d(stimEnd+1:stimEnd+capLen) - d(stimEnd+capLen);
    c_v2Tov3Cap(cei, :) = v2Tov3Cap;
end
direction = 0; % which way is it wrong?
if v2Tov3Cap(50) > 0
    direction = 1;
elseif v2Tov3Cap(50) < 0
    direction = -1;
end

% condense TTX (control) capacitance traces
uniqueSteps = unique(cpulse1Curr);
nSteps = length(uniqueSteps); % could contain ds with many diff steps
c_v0Tov1CapMean = zeros(nSteps, capLen);
c_v1Tov2CapMean = zeros(nSteps, capLen);
c_v2Tov3CapMean = zeros(nSteps, capLen);
for ui = 1:nSteps
    step = uniqueSteps(ui);
    ind = (cpulse1Curr == step);
    c_v0Tov1CapMean(ui, :) = nanmean(c_v0Tov1Cap(ind, :));
    c_v1Tov2CapMean(ui, :) = nanmean(c_v1Tov2Cap(ind, :));
    c_v2Tov3CapMean(ui, :) = nanmean(c_v2Tov3Cap(ind, :));
end

compEpochs = false(cellData.get('Nepochs'), 1);
compData = nan(cellData.get('Nepochs'), length(d));
% subtract TTX (control) traces from the compensate DS
for di = 1:length(DStoComp)
    dataEpochs = cellData.savedDataSets(DStoComp{di}); 
    for cei = 1:length(dataEpochs)
        e = cellData.epochs(dataEpochs(cei));
        step = e.get('pulse1Curr');
        ind = (uniqueSteps == step); % index in control data! for cap trace
        if sum(ind) == 0 % if this step was not in the control data find the closest one
            [~,idx]=min(abs(uniqueSteps-step));
            newStep=uniqueSteps(idx);
            ind = (uniqueSteps == newStep);
        end
        d = e.getData();
        % determine scaling
        data_v2Tov3Cap = d(stimEnd+1:stimEnd+capLen) - d(stimEnd+capLen);
        scalingFactor = max(c_v2Tov3CapMean(ind, :))/max(data_v2Tov3Cap);
        % compensate
        d(stim1Start+1:stim1Start+capLen) = d(stim1Start+1:stim1Start+capLen) - scalingFactor*c_v0Tov1CapMean(ind, :)';
        d(stim2Start+1:stim2Start+capLen) = d(stim2Start+1:stim2Start+capLen) - scalingFactor*c_v1Tov2CapMean(ind, :)';
        d(stimEnd+1:stimEnd+capLen) = d(stimEnd+1:stimEnd+capLen) - scalingFactor*c_v2Tov3CapMean(ind, :)';
        if max(d) > 1E5
            % then something went wrong in the capacitance compensation
            % likely a bad epoch
            warning('Cap Compensation went awry for epoch #%d', dataEpochs(cei))
        end
        % save in compData
        compEpochs(dataEpochs(cei), 1) = 1; % flag that this epoch has been compensated
        compData(dataEpochs(cei), :) = d;
    end
end

if saveFlag
    if ~exist(fileName)
        save(fileName, 'compEpochs', 'compData');
    else
        % intregrate into already run folder
        old = load(fileName);
        ind = find(compEpochs);
        old.compEpochs(ind) = 1;
        old.compData(ind, :) = compData(ind, :);
        compEpochs = old.compEpochs;
        compData = old.compData;
        save(fileName, 'compEpochs', 'compData');
    end
end

end

