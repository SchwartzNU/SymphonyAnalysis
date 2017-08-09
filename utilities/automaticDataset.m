%% Automatic dataset
%#ok<*SAGROW>

indices = [];
oi = 0;

displayName = 'Moving Bar';
datasetNameHeader = 'MovingBar';
paramNamesList = {'barSpeed','barWidth','ampHoldSignal'};
shortNamesList = {'speed','width','voltage'};
paramValuesByEpoch = [];


for ei=1:length(cellData.epochs)
    epoch = cellData.epochs(ei);

    if ~strcmp(epoch.get('displayName'), displayName)
        continue
    end
    
    if epoch.get('barLength') <= 2000
        continue
    end
    
    if ~isnan(epoch.get('exclude'))
        continue
    end

    oi = oi + 1;
    indices(oi,1) = ei;

    for pi = 1:length(paramNamesList)
        paramValuesByEpoch(oi,pi) = epoch.get(paramNamesList{pi});
    end

end

uniqueValuesByParameter = {};
for pi = 1:length(paramNamesList)
    uniqueValuesByParameter{pi} = unique(paramValuesByEpoch(:,pi)); 
end

% look for any data set that matches parameters
datasetValuesByValueset = [];
epochIndicesByValueset = {};
oi = 0;
if length(paramNamesList) == 2
    for i1 = 1:length(uniqueValuesByParameter{1})
        for i2 = 1:length(uniqueValuesByParameter{2})        
            oi = 1 + oi;
            datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{1}(i1), uniqueValuesByParameter{2}(i2)];
            epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch, datasetValuesByValueset(oi, :), 'rows'));
        end
    end
elseif length(paramNamesList) == 3
    for i1 = 1:length(uniqueValuesByParameter{1})
        for i2 = 1:length(uniqueValuesByParameter{2})
            for i3 = 1:length(uniqueValuesByParameter{3})
                oi = 1 + oi;
                datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{1}(i1), uniqueValuesByParameter{2}(i2), uniqueValuesByParameter{3}(i3)];
                epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch, datasetValuesByValueset(oi, :), 'rows'));
            end
        end
    end
elseif length(paramNamesList) == 4
    for i1 = 1:length(uniqueValuesByParameter{1})
        for i2 = 1:length(uniqueValuesByParameter{2})
            for i3 = 1:length(uniqueValuesByParameter{3})
                for i4 = 1:length(uniqueValuesByParameter{4})            
                    oi = 1 + oi;
                    datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{1}(i1), uniqueValuesByParameter{2}(i2), uniqueValuesByParameter{3}(i3), uniqueValuesByParameter{4}(i4)];
                    epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch, datasetValuesByValueset(oi, :), 'rows'));
                end
            end
        end
    end
end

% pull out the valid data sets
oi = 0;
datasetValuesValid = [];
for di = 1:size(epochIndicesByValueset,1)
    epochIndices = epochIndicesByValueset{di,1};
    if isempty(epochIndices)
        continue
    end
    
    datasetName = datasetNameHeader;
    for pi = 1:length(paramNamesList)
        datasetName = [datasetName, sprintf(' %s:%g',shortNamesList{pi}, datasetValuesByValueset(di,pi))];
        
    end
    datasetValuesValid(end+1,:) = datasetValuesByValueset(di,:);
    fprintf('Added %s with %g epochs\n', datasetName, length(epochIndices));
    if length(epochIndices) > 7
        cellData.savedDataSets(datasetName) = epochIndices';
    end
end
%%
% ks = keys(cellData.savedDataSets);
% for i = 1:length(ks)
%     if strcmp(ks{i}(1:9), 'MovingBar')
%         remove(cellData.savedDataSets, ks{i})
%     end
% end
    
