function [allCellNames, sp, dataError] = collectSpikeTimesFromBigDataStruct(dataSetTable)
global RAW_DATA_FOLDER;
rawData_folder = uigetdir([],'Choose raw data folder from which to copy data');

Ncells = length(dataSetTable);
sp = cell(1,Ncells);
allCellNames = cell(1,Ncells);
dataError = zeros(1,Ncells);

for i=1:Ncells
    temp = textscan(dataSetTable{i}, '%s', 'Delimiter', ':');
    temp = temp{1};
    cellData_name = temp{1};
    dataSet_name = temp{2};
    allCellNames{i} = cellData_name;
    cellData = loadAndSyncCellData(cellData_name);
    epochID = cellData.savedDataSets(dataSet_name);
    
    try
        copiedData = false;
        rawData_fname = [cellData_name '.h5'];
        if exist([RAW_DATA_FOLDER rawData_fname], 'file') %already have the file
            %do nothing
        else
            copiedData = true;
            if exist([rawData_folder filesep rawData_fname], 'file')
                disp(['Copying ' rawData_fname]);
                eval(['!cp -r ' [rawData_folder filesep rawData_fname] ' ' RAW_DATA_FOLDER]);
            else
                disp([rawData_folder filesep rawData_fname ' not found']);
            end
        end
        
        [PSTH, timeAxis_PSTH] = cellData.getPSTH(epochID);
        L = length(epochID);
        spikeTimes = cell(L,1);
        for e=1:L
            [spikeTimes{e}, timeAxis_spikes] = cellData.epochs(epochID(e)).getSpikes();
        end
        sp{i} = spikeTimes;
        
        %delete this copy to save hard drive space
        if copiedData
            disp('Deleting rawData');
            eval(['!rm ' [RAW_DATA_FOLDER filesep rawData_fname]])
        end
    catch
        dataError(i) = 1;
    end
end
