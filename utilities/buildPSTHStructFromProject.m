function [single_LS_table, multi_LS_table, error_cells] = buildPSTHStructFromProject(epochFilter_LS, epochFilter_SMS, projFolder)
ANALYSIS_FOLDER = getenv('ANALYSIS_FOLDER');
PREFERENCE_FILES_FOLDER = getenv('PREFERENCE_FILES_FOLDER');

if nargin < 3
    projFolder = uigetdir([ANALYSIS_FOLDER filesep 'Projects' filesep], 'Choose project folder');
end

fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
if fid < 0
    errordlg(['Error: cellNames.txt not found in ' projFolder]);
    return;
end
temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

%load analysis table
fid = fopen([PREFERENCE_FILES_FOLDER filesep 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

%find correct row in this table
Nanalyses = length(analysisTable{1});
analysisIndices = [];
for dsi=1:Nanalyses
    if strcmp(analysisTable{2}{dsi}, 'LightStepAnalysis')
        analysisIndices(end+1) = dsi;
    end
end
if isempty(analysisIndices)
    fprintf('Error: analysis %s not found in DataSetAnalyses.txt\n', analysisClassName);
    resultTree = [];
    return;
end

%find correct row in this table for SMS
analysisIndices_SMS = [];
for dsi=1:Nanalyses
    if strcmp(analysisTable{2}{dsi}, 'SpotsMultiSizeAnalysis')
        analysisIndices_SMS(end+1) = dsi;
    end
end
if isempty(analysisIndices)
    fprintf('Error: analysis %s not found in DataSetAnalyses.txt\n', analysisClassName);
    resultTree = [];
    return;
end

error_cells = {};

single_LS_table = table({},{},{},{}, 'VariableNames', {'cellName', 'dataSet', 'dataSetType' 'cellType'});
multi_LS_table = table({},{},{},{}, 'VariableNames', {'cellName', 'dataSet', 'dataSetType', 'cellType'});

single_ind = 1;
multi_ind = 1;
for i=1:length(cellNames)
    cellDataName = cellNameToCellDataNames(cellNames{i});
    
    %load cellData
    cellData = loadAndSyncCellData(cellDataName{1});
    
    %get dataset list
    dataSetKeys = cellData.savedDataSets.keys;
    
    matchingDataSets = {};
    for dsi=1:length(dataSetKeys)
        curDataSet = dataSetKeys{dsi};
        for anal_ind=1:length(analysisIndices)
            if strfind(curDataSet, analysisTable{1}{analysisIndices(anal_ind)}) %if correct data set type
                %evaluate epochFilter
                if ~isempty(epochFilter_LS)
                    filterOut = cellData.filterEpochs(epochFilter_LS.makeQueryString(), cellData.savedDataSets(curDataSet));
                    if length(filterOut) == length(cellData.savedDataSets(curDataSet)) %all epochs match filter
                        matchingDataSets = [matchingDataSets; curDataSet];
                    end
                end
            end
        end
    end
    
    if length(matchingDataSets) == 1
        single_LS_table(single_ind,:) = cell2table({cellDataName, matchingDataSets, 'LS', cellData.cellType});
        single_ind = single_ind+1;
    elseif length(matchingDataSets) > 1
        multi_LS_table(multi_ind,:) = cell2table({cellDataName, matchingDataSets, 'LS', cellData.cellType});
        multi_ind = multi_ind+1;
    elseif isempty(matchingDataSets) % no LS dataset found so looking for SMS
        for dsi=1:length(dataSetKeys)
            curDataSet = dataSetKeys{dsi};
            for anal_ind=1:length(analysisIndices_SMS)
                if strfind(curDataSet, analysisTable{1}{analysisIndices_SMS(anal_ind)}) %if correct data set type
                    %evaluate epochFilter
                    if ~isempty(epochFilter_SMS)
                        filterOut = cellData.filterEpochs(epochFilter_SMS.makeQueryString(), cellData.savedDataSets(curDataSet));
                        if length(filterOut) == length(cellData.savedDataSets(curDataSet)) %all epochs match filter
                            matchingDataSets = [matchingDataSets; curDataSet];
                        end
                    end
                end
            end
        end
        %matchingDataSets for SMS
        if length(matchingDataSets) == 1
            single_LS_table(single_ind,:) = cell2table({cellDataName, matchingDataSets, 'SMS', cellData.cellType});
            single_ind = single_ind+1;
        elseif length(matchingDataSets) > 1
            multi_LS_table(multi_ind,:) = cell2table({cellDataName, matchingDataSets, 'SMS', cellData.cellType});
            multi_ind = multi_ind+1;
        else
            error_cells = [error_cells; cellDataName];
        end        
    else        
        error_cells = [error_cells; cellDataName];
    end
    disp(['i=' num2str(i) ' single_ind=' num2str(single_ind), ' multi_ind=' num2str(multi_ind)]);
end