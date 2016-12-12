

load cellData/102816Ac3.mat
epochIndices = [311 314 317];

% load cellData/102516Ac2.mat
% epochIndices = [167];

modelStruct = noiseFilter(cellData, epochIndices);

figure(201);clf;
% plot(t, allFilters);
% hold on
allFilters = cell2mat(modelStruct.filtersByEpoch);
mn = mean(allFilters);
se = std(allFilters)/sqrt(size(allFilters, 1));
plot(modelStruct.timeByEpoch{1}, [mn; mn+se; mn-se], 'LineWidth', 1)
% hold off
title('Filter mean and sem')
