

% load cellData/102816Ac3.mat
% epochIndices = [311 314 317];

% load cellData/102516Ac2.mat
% epochIndices = [167];

load cellData/110216Ac19.mat
epochIndices = 218:251;

% spiking WFDS
load cellData/121616Ac2.mat 
epochIndices = 133:135;

centerEpochs = [];
numberOfEpochs = length(epochIndices);
for ei=1:numberOfEpochs

    epoch = cellData.epochs(epochIndices(ei));
    centerNoiseSeed = epoch.get('centerNoiseSeed')
    stimulusAreaMode = epoch.get('currentStimulus');

    if strcmp(stimulusAreaMode, 'Center')
        centerEpochs(end+1) = epochIndices(ei);
    end
end
epochIndices = centerEpochs;

modelStruct = noiseFilter(cellData, epochIndices, 'NIM LN');

% figure(201);clf;
% % plot(t, allFilters);
% % hold on
% allFilters = cell2mat(modelStruct.filtersByEpoch);
% mn = mean(allFilters);
% se = std(allFilters)/sqrt(size(allFilters, 1));
% plot([mn; mn+se; mn-se]', 'LineWidth', 1)
% % hold off
% title('Filter mean and sem')
