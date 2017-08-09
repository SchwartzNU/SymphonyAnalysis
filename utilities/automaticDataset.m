%% Automatic dataset
% load cellData
% use save(['cellData/' cellData.savedFileName], 'cellData')


%#ok<*SAGROW>

indices = [];
oi = 0;

% displayName = 'Moving Bar';
% datasetNameHeader = 'MovingBar';
displayName = 'Pulse';
datasetNameHeader = 'Pulse';
% displayName = 'Spots Multi Size';
% datasetNameHeader = 'SpotsMultiSize';

paramNamesList = {'barSpeed','barWidth','intensity','meanLevel','outputAmpSelection','NDF','ampHoldSignal'};
shortNamesList = {'speed','width','int','mean','outputAmp','NDF','v'};
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
usefulParametersIndices = [];
for pi = 1:length(paramNamesList)
    uniqueValuesByParameter{pi} = unique(paramValuesByEpoch(:,pi));
    if all(isnan(uniqueValuesByParameter{pi}))
        continue
    end
    if length(uniqueValuesByParameter{pi}) > 1
        usefulParametersIndices(end+1) = pi;
    end
end

% pull out the parameters that are worth including



% look for any data set that matches parameters
datasetValuesByValueset = [];
epochIndicesByValueset = {};
oi = 0;

if length(usefulParametersIndices) == 1
    for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
        oi = 1 + oi;
        datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1)];
        epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :), 'rows'));
    end
elseif length(usefulParametersIndices) == 2
    for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
        for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})        
            oi = 1 + oi;
            datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2)];
            epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :), 'rows'));
        end
    end
elseif length(usefulParametersIndices) == 3
    for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
        for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})
            for i3 = 1:length(uniqueValuesByParameter{usefulParametersIndices(3)})
                oi = 1 + oi;
                datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2), uniqueValuesByParameter{usefulParametersIndices(3)}(i3)];
                epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :), 'rows'));
            end
        end
    end
elseif length(usefulParametersIndices) == 4
    for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
        for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})
            for i3 = 1:length(uniqueValuesByParameter{usefulParametersIndices(3)})
                for i4 = 1:length(uniqueValuesByParameter{usefulParametersIndices(4)})            
                    oi = 1 + oi;
                    datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2), uniqueValuesByParameter{usefulParametersIndices(3)}(i3), uniqueValuesByParameter{usefulParametersIndices(4)}(i4)];
                    epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :), 'rows'));
                end
            end
        end
    end
elseif length(usefulParametersIndices) == 5
    for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
        for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})
            for i3 = 1:length(uniqueValuesByParameter{usefulParametersIndices(3)})
                for i4 = 1:length(uniqueValuesByParameter{usefulParametersIndices(4)})            
                    for i5 = 1:length(uniqueValuesByParameter{usefulParametersIndices(5)})            
                        oi = 1 + oi;
                        datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2), uniqueValuesByParameter{usefulParametersIndices(3)}(i3), uniqueValuesByParameter{usefulParametersIndices(4)}(i4), uniqueValuesByParameter{usefulParametersIndices(5)}(i5)];
                        epochIndicesByValueset{oi,1} = indices(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :), 'rows'));
                    end
                end
            end
        end
    end
else
    warning('Too many varying parameters')
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
    for pi = 1:length(usefulParametersIndices)
        paramIndex = usefulParametersIndices(pi);
        datasetName = [datasetName, sprintf(' %s:%g',shortNamesList{paramIndex}, datasetValuesByValueset(di,pi))];
        
    end
    datasetValuesValid(end+1,:) = datasetValuesByValueset(di,:);
    
    if length(epochIndices) > 7
        fprintf('Added %s with %g epochs\n', datasetName, length(epochIndices));
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
    
