function [single_SMS_table, multi_SMS_table, error_cells] = buildSMSStructFromProject(epochFilter, projFolder)
global ANALYSIS_FOLDER;
global PREFERENCE_FILES_FOLDER

if nargin < 2
    projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep], 'Choose project folder');
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
fid = fopen([PREFERENCE_FILES_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

%find correct row in this table
Nanalyses = length(analysisTable{1});
analysisIndices = [];
for dsi=1:Nanalyses
    if strcmp(analysisTable{2}{dsi}, 'SpotsMultiSizeAnalysis')
        analysisIndices(end+1) = dsi;
    end
end
if isempty(analysisIndices)
    fprintf('Error: analysis %s not found in DataSetAnalyses.txt\n', analysisClassName);
    resultTree = [];
    return;
end

error_cells = {};

single_SMS_table = table({},{},{}, 'VariableNames', {'cellName', 'dataSet', 'cellType'});
multi_SMS_table = table({},{},{}, 'VariableNames', {'cellName', 'dataSet', 'cellType'});

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
                if ~isempty(epochFilter)
                    filterOut = cellData.filterEpochs(epochFilter.makeQueryString(), cellData.savedDataSets(curDataSet));
                    if length(filterOut) == length(cellData.savedDataSets(curDataSet)) %all epochs match filter
                        matchingDataSets = [matchingDataSets; curDataSet];
                    end
                end
            end
        end
    end
    if length(matchingDataSets) == 1
        single_SMS_table(single_ind,:) = cell2table({cellDataName, matchingDataSets, cellData.cellType});
        single_ind = single_ind+1;
    elseif length(matchingDataSets) > 1
        multi_SMS_table(multi_ind,:) = cell2table({cellDataName, matchingDataSets, cellData.cellType});
        multi_ind = multi_ind+1;
    else
        error_cells = [error_cells; cellDataName];
    end
    disp(['i=' num2str(i) ' single_ind=' num2str(single_ind), ' multi_ind=' num2str(multi_ind)]);
end