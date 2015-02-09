function [] = splitOffDataSet_LightStepFromSpotsMultiSize
optimalSpotSize = 200;

if exist([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster']) == 7
    cellDataMasterFolder = [filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster'];
else
    disp('Could not connect to CellDataMaster');
    return;
end

%get all cellData names in CellDataMaster
cellDataNames = ls([cellDataMasterFolder filesep '*.mat']);
cellDataNames = strsplit(cellDataNames); %this will be different on windows - see doc ls
cellDataNames = sort(cellDataNames);

cellDataBaseNames = cell(length(cellDataNames), 1);
z = 1;
for i=1:length(cellDataNames)
    [~, basename, ~] = fileparts(cellDataNames{i});
    if ~isempty(basename)
        cellDataBaseNames{z} = basename;
        z=z+1;
    end
end

L = length(cellDataBaseNames);
for i=1:L
    disp(['Cell ' num2str(i) ' of ' num2str(L)]);
    if ~isempty(cellDataBaseNames{i})
        load([cellDataMasterFolder filesep cellDataBaseNames{i}]); %loads cellData
        %check for dataset and add to ProjMap (in this case only one key)
        dataSetNames = cellData.savedDataSets.keys;
        ind = strfind(dataSetNames, 'SpotsMultiSize');
        %ind = strfind(dataSetNames, 'fromSMS');
        for d=1:length(ind);
            if ~isempty(ind{d})  %if has dataSet with prefix
                %                 oldName = dataSetNames{d};
                %                 newName = regexprep(oldName, 'fromSpotsMultiSize', 'fromSMS');
                %                 IDs = cellData.savedDataSets(oldName);
                %                 filt = cellData.savedFilters(oldName);
                %                 cellData.savedDataSets.remove(oldName);
                %                 cellData.savedDataSets(newName) = IDs;
                %                 cellData.savedFilters(newName) = filt;     
                curInd = d;
                disp(['Found ' dataSetNames{curInd} ' in ' cellData.savedFileName]);
                if  cellData.savedDataSets.isKey(dataSetNames{curInd})
                    remove(cellData.savedDataSets, dataSetNames{curInd});
                end
                if cellData.savedFilters.isKey(dataSetNames{curInd})
                    remove(cellData.savedFilters, dataSetNames{curInd});
                end
                
                %                 disp(['SpotsMultiSize found in cell '  cellDataBaseNames{i} ' dataSet: ' dataSetNames{d}]);
                %                 curEpochIDs = cellData.savedDataSets(dataSetNames{d});
                %                 spotSizes = cellData.getEpochVals('curSpotSize', curEpochIDs);
                %                 uniqueSizes = unique(spotSizes);
                %                 [~, tempInd] = min(abs(uniqueSizes - optimalSpotSize));
                %                 matchingSize = uniqueSizes(tempInd);
                %                 matchingEpochIDs = spotSizes == matchingSize;
                %                 %now make new dataset
                %                 newDataSetName = ['LightStep_from' regexprep(dataSetNames{d}, 'SpotsMultiSize', 'SMS') '_size' num2str(round(matchingSize))];
                %                 newEpochIDs = curEpochIDs(matchingEpochIDs);
                %                 cellData.savedDataSets(newDataSetName) = newEpochIDs;
                %                 %tag each epoch
                %                 for ep = 1:length(newEpochIDs)
                %                     cellData.epochs(newEpochIDs(ep)).attributes('spotSize') = round(matchingSize);
                %                     cellData.epochs(newEpochIDs(ep)).attributes(['autoDataSet_' newDataSetName]) = 1;
                %                 end
                %                 tempStruct.filterPatternString = '@1';
                %                 tempStruct.filterData = {['autoDataSet_' newDataSetName], '==', '1'} ;
                %                 cellData.savedFilters(newDataSetName) = tempStruct;
                 save([cellDataMasterFolder filesep cellDataBaseNames{i}], 'cellData')
            end
        end
    end
end
