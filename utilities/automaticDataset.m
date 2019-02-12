%% Automatic dataset
% load cellData
% use save(['cellData/' cellData.savedFileName], 'cellData')


% undo code:
% k = cellData.savedDataSets.keys();
% for i = 1:50
%     if strfind(k{i}, 'MovingBar')
%         remove(cellData.savedDataSets, k{i})
%     end
% end


%#ok<*SAGROW>

displayNames = {'Moving Bar'}; %,'Split Field','Pulse','Spots Multi Size', 'Contrast Response'
displayNameHeaders = {'MovingBar','SplitField','Pulse','SpotsMultiSize','ContrastResponse'};

for dni = 1:length(displayNames)
    displayName = displayNames{dni}
    displayNameHeader = displayNameHeaders{dni};

    
    paramNamesList = {'barSpeed','barWidth','intensity','barLength','meanLevel','outputAmpSelection',...
        'NDF','ampHoldSignal','barSeparation','contrastSide1','ContrastSide2','ampMode',...
        'motionSeed','ablation'};
    shortNamesList = {'speed','width','int','len','mean','outputAmp','NDF','v','sep','c1','c2','','seed','abl'};
    paramValuesByEpoch = {};
    
    indices = [];
    oi = 0;
    
    for ei=1:length(cellData.epochs)
        epoch = cellData.epochs(ei);
        
%         epoch.get('displayName')
        
        if ~strcmp(epoch.get('displayName'), displayName)
            continue
        end
        
        %     if epoch.get('barLength') <= 2000
        %         continue
        %     end
        
        if ~isnan(epoch.get('exclude'))
            continue
        end
        
        oi = oi + 1;
        indices(oi,1) = ei;
        
        for pi = 1:length(paramNamesList)
            paramValuesByEpoch{oi,pi} = num2str(epoch.get(paramNamesList{pi}));
        end
        
    end
    
    if isempty(paramValuesByEpoch)
        continue;
    end
    
    uniqueValuesByParameter = {};
    usefulParametersIndices = [];
    for pi = 1:length(paramNamesList)
        uniqueValuesByParameter{pi} = unique(paramValuesByEpoch(:,pi));
        if all(contains(uniqueValuesByParameter{pi}, 'NaN'))
            continue
        end
        if length(uniqueValuesByParameter{pi}) > 1
            usefulParametersIndices(end+1) = pi;
        end
    end
    
    % pull out the parameters that are worth including
    
    
    
    % look for any data set that matches parameters
    datasetValuesByValueset = {};
    epochIndicesByValueset = {};
    oi = 0;
    
    if length(usefulParametersIndices) == 1
        for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
            oi = 1 + oi;
            datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1)];
            epochIndicesByValueset{oi,1} = indices(all(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :)), 2));
        end
    elseif length(usefulParametersIndices) == 2
        for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
            for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})
                oi = 1 + oi;
                datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2)];
                epochIndicesByValueset{oi,1} = indices(all(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :)), 2));
            end
        end
    elseif length(usefulParametersIndices) == 3
        for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
            for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})
                for i3 = 1:length(uniqueValuesByParameter{usefulParametersIndices(3)})
                    oi = 1 + oi;
                    datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2), uniqueValuesByParameter{usefulParametersIndices(3)}(i3)];
                    epochIndicesByValueset{oi,1} = indices(all(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :)), 2));
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
                        epochIndicesByValueset{oi,1} = indices(all(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :)), 2));
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
                            epochIndicesByValueset{oi,1} = indices(all(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :)), 2));
                        end
                    end
                end
            end
        end
    elseif length(usefulParametersIndices) == 8
        for i1 = 1:length(uniqueValuesByParameter{usefulParametersIndices(1)})
            for i2 = 1:length(uniqueValuesByParameter{usefulParametersIndices(2)})
                for i3 = 1:length(uniqueValuesByParameter{usefulParametersIndices(3)})
                    for i4 = 1:length(uniqueValuesByParameter{usefulParametersIndices(4)})
                        for i5 = 1:length(uniqueValuesByParameter{usefulParametersIndices(5)})
                            for i6 = 1:length(uniqueValuesByParameter{usefulParametersIndices(6)})
                                for i7 = 1:length(uniqueValuesByParameter{usefulParametersIndices(7)})
                                    for i8 = 1:length(uniqueValuesByParameter{usefulParametersIndices(8)})                            
                                        oi = 1 + oi;
                                        datasetValuesByValueset(oi,:) = [uniqueValuesByParameter{usefulParametersIndices(1)}(i1), uniqueValuesByParameter{usefulParametersIndices(2)}(i2), uniqueValuesByParameter{usefulParametersIndices(3)}(i3), uniqueValuesByParameter{usefulParametersIndices(4)}(i4), uniqueValuesByParameter{usefulParametersIndices(5)}(i5), uniqueValuesByParameter{usefulParametersIndices(6)}(i6), uniqueValuesByParameter{usefulParametersIndices(7)}(i7), uniqueValuesByParameter{usefulParametersIndices(8)}(i8)];
                                        
                                        paramValuesByEpoch(:,usefulParametersIndices)
                                        datasetValuesByValueset(oi, :)
                                        epochIndicesByValueset{oi,1} = indices(all(ismember(paramValuesByEpoch(:,usefulParametersIndices), datasetValuesByValueset(oi, :)), 2));
                                        epochIndicesByValueset{oi,1}
                                        paramValuesByEpoch(epochIndicesByValueset{oi,1}, :)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else        
        warning('Too many or few varying parameters')
    end
    
    % pull out the valid data sets
    oi = 0;
    datasetValuesValid = [];
    for di = 1:size(epochIndicesByValueset,1)
        epochIndices = epochIndicesByValueset{di,1};
        if isempty(epochIndices)
            continue
        end
        epochIndices
        
        datasetName = displayNameHeader;
        for pi = 1:length(usefulParametersIndices)
            paramIndex = usefulParametersIndices(pi);
            
            %handle CA vs WC differently, not a generalized bit of code like it should be
            if ~strcmp(paramNamesList{paramIndex}, 'ampMode')
                datasetName = [datasetName, sprintf(' %s:%s', shortNamesList{paramIndex}, datasetValuesByValueset{di,pi})];
            else
                if strcmp(datasetValuesByValueset(di,pi), 'Whole cell')
                    valueText = 'wc';
                else
                    valueText = 'ca';
                end
                datasetName = [datasetName, sprintf(' %s', valueText)];
            end
            
        end
%         datasetValuesValid(end+1,:) = datasetValuesByValueset{di,:};
        
        if length(epochIndices) > 7
            fprintf('Added %s with %g epochs\n', datasetName, length(epochIndices));
            cellData.savedDataSets(datasetName) = epochIndices';
        end
    end
    
end
%%
% ks = keys(cellData.savedDataSets);
% for i = 1:length(ks)
%     if strcmp(ks{i}(1:9), 'MovingBar')
%         remove(cellData.savedDataSets, ks{i})
%     end
% end

