%% Cell data summary processing script
% Script loads analysis trees and compiles all the results into a table
% 
% This table can be used easily and flexibly to make analysis and comparisons
% 
% Make the file for loading and processing in the LabDataGui
% 
% Edit and run this code segment, then use the button in the bottom right 
% corner of the LabDataGUI to open the filterFileNames file

filterFileNames = {'analysisTrees/automaticData/filter light step CA.mat';
    'analysisTrees/automaticData/filter sms CA.mat';
    'analysisTrees/automaticData/filter drifting texture CA.mat';
    'analysisTrees/automaticData/filter drifting gratings CA.mat';
    'analysisTrees/automaticData/filter sms WC -60.mat';
    'analysisTrees/automaticData/filter sms WC 20.mat';
    'analysisTrees/automaticData/filter moving bar 1000 narrow CA.mat';
    'analysisTrees/automaticData/filter moving bar 500 narrow CA.mat';
    'analysisTrees/automaticData/filter moving bar 250 narrow CA.mat';
    'analysisTrees/automaticData/filter light step WC -60.mat';
    'analysisTrees/automaticData/filter light step WC 20.mat';
    'analysisTrees/automaticData/filter contrast CA.mat';
    };


save('analysisTrees/automaticData/filterFileNames', 'filterFileNames');
%% Accumulate all parameters
% Modify the cellNameReplacements variable to compensate for joined cells. Not 
% pretty, but it works.

treeVariableModes = [1,0,1,1,0,0,1,1,1,2,2,0]; % 1 for single params (Light step on spike count mean), 0 for vectors (spike count by spot size), 2 for extracting params for a curve
paramsByTree = {{'ONSETspikes_mean', 'OFFSETspikes_mean'};
    {'ONSETspikes','OFFSETspikes','ONSETrespDuration'};
    {'spikeCount_stimAfter500ms_mean','spikeCount_stimAfter500ms_DSI', 'spikeCount_stimAfter500ms_DSang','spikeCount_stimAfter500ms_OSI', 'spikeCount_stimAfter500ms_OSang', 'spikeCount_stimAfter500ms_DVar'};
    {'F1amplitude_mean','F1amplitude_DSI','F1amplitude_DSang','F1amplitude_OSI','F1amplitude_OSang','F1amplitude_DVar'}
    {'stimInterval_charge','ONSET_peak'};
    {'stimInterval_charge','ONSET_peak'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'params'};
    {'params'};
    {'ONSETspikes','ONSETlatency'};};
paramsColumnNamesByTree = {{'LS_ON_sp','LS_OFF_sp'};
    {'SMS_spotSize_sp','SMS_onSpikes','SMS_offSpikes','SMS_onDuration'};
    {'DrifTex_mean_sp','DrifTex_DSI_sp','DrifTex_DSang_sp','DrifTex_OSI_sp','DrifTex_OSang_sp','DrifTex_DVar_sp'};
    {'DrifGrat_mean_sp','DrifGrat_DSI_sp','DrifGrat_DSang_sp','DrifGrat_OSI_sp','DrifGrat_OSang_sp','DrifGrat_DVar_sp'};
    {'SMS_spotSize_ex','SMS_charge_ex','SMS_peak_ex'};
    {'SMS_spotSize_in','SMS_charge_in','SMS_peak_in'};
    {'MB_1000_mean_sp','MB_1000_DSI_sp','MB_1000_DSang_sp','MB_1000_OSI_sp','MB_1000_OSang_sp','MB_1000_DVar_sp'};
    {'MB_500_mean_sp','MB_500_DSI_sp','MB_500_DSang_sp','MB_500_OSI_sp','MB_500_OSang_sp','MB_500_DVar_sp'};
    {'MB_250_mean_sp','MB_250_DSI_sp','MB_250_DSang_sp','MB_250_OSI_sp','MB_250_OSang_sp','MB_250_DVar_sp'};
    {'LS_ON_params_ex'};
    {'LS_ON_params_in'};
    {'Contrast_contrastVal_sp','Contrast_onSpikes','Contrast_onLatency'};};

% on
cellNameReplacements = containers.Map();
cellNameReplacements('010716Ac4') = '010716Ac1';
cellNameReplacements('010716Ac2') = '010716Ac1';
cellNameReplacements('011216Ac4') = '011216Ac3';
cellNameReplacements('020516Ac9') = '020516Ac8';
cellNameReplacements('030515Bc4') = '030515Bc3';
cellNameReplacements('030515Bc12') = '030515Bc3';
cellNameReplacements('040716Ac8') = '040716Ac6';
cellNameReplacements('041416Ac10') = '041416Ac9';
cellNameReplacements('041416Ac11') = '041416Ac9';
cellNameReplacements('042116Ac3') = '042116Ac2';
cellNameReplacements('070115Ac6') = '070115Ac5';
cellNameReplacements('082814Bc4') = '082814Bc3';
cellNameReplacements('092016Ac8') = '092016Ac7';
cellNameReplacements('092716Ac14') = '092716Ac13';
cellNameReplacements('111915Ac5') = '111915Ac3';
cellNameReplacements('111915Ac6') = '111915Ac4';
% off
cellNameReplacements('040716Ac5') = '040716Ac2';
%ULD
cellNameReplacements('041416Ac12') = '041416Ac13';

%% load cell names for data

tic
numTrees = length(treeVariableModes);

allCellNames = {};
for ti = 1:numTrees
    fname = fullfile('analysisTrees/automaticData/treeData/', num2str(ti));
    fprintf('Loading tree %s for cell names\n', fname)
    load(fname);
    fprintf('Processing tree\n');
    cellNames = {};
    
    if treeVariableModes(ti) == 1
        [cellNames, ~, ~] = allParamsAcrossCells(analysisTree, paramsByTree{ti,:});
    elseif treeVariableModes(ti) == 0
        data = extractVectorOverSplitParamFromMultiCellTree(analysisTree, paramsByTree{ti,:});
        if ~isempty(data)
            cellNames = data(:,1);
        end
    elseif treeVariableModes(ti) == 2
        data = extractLightStepParamsFromTree(analysisTree, true);
        if ~isempty(data)
            cellNames = data(:,1);
        end
    end
    
    for ni = 1:length(cellNames)
        if isKey(cellNameReplacements, cellNames{ni})
            cellNames{ni} = cellNameReplacements(cellNames{ni});
        end
    end
    allCellNames = vertcat(allCellNames, cellNames);
end

allCellNames = unique(allCellNames);
disp('done loading')
toc
%% build table

warning('off','MATLAB:table:RowsAddedNewVars')
dtab = table('RowNames',allCellNames);
tic

for ti = 1:numTrees
    fname = fullfile('analysisTrees/automaticData/treeData/', num2str(ti));
    fprintf('Loading tree %s (%g of %g) \n', fname, ti, numTrees)
    load(fname);
    disp('Processing');
    
    if treeVariableModes(ti) == 1
        
        [cellNames, dataSetNames, paramForCells] = allParamsAcrossCells(analysisTree, paramsByTree{ti,:});
        % add new columns from this data set
        dtab(:,paramsColumnNamesByTree{ti}) = num2cell(nan(length(allCellNames), length(paramsColumnNamesByTree{ti})));
        % fill these new empty columns
        paramForCells(cellfun(@isempty, paramForCells)) = {nan};
        paramForCells = paramForCells';
        % load the columns with data
        for ci = 1:length(cellNames)
            name = cellNames{ci};
            if isKey(cellNameReplacements, name)
                name = cellNameReplacements(name);
            end
            dtab(name, paramsColumnNamesByTree{ti}) = paramForCells(ci,:);
        end
    elseif treeVariableModes(ti) == 0
        data = extractVectorOverSplitParamFromMultiCellTree(analysisTree, paramsByTree{ti,:});
        if ~isempty(data)
            cellNames = data(:,1);
            for ci = 1:length(cellNames)
                name = cellNames{ci};
                if isKey(cellNameReplacements, name)
                    name = cellNameReplacements(name);
                end            
                dtab{name,paramsColumnNamesByTree{ti}} = data(ci,2:end);
            end
        end
    elseif treeVariableModes(ti) == 2
        data = extractLightStepParamsFromTree(analysisTree, false);
        if ~isempty(data)
            cellNames = data(:,1);
        
             
            for ci = 1:length(cellNames)
                name = cellNames{ci};
                if isKey(cellNameReplacements, name)
                    name = cellNameReplacements(name);
                end            
                dtab{name,paramsColumnNamesByTree{ti}} = data(ci,3);
            end
        end

    end
    %     if cellType(ti)
    %         for i = 1:length(cellNames)
    %             dtab{cellNames{i}, 'cellType'} = {'WFDS ON'};
    %         end
    %     else
    %         for i = 1:length(cellNames)
    %             dtab{cellNames{i}, 'cellType'} = {'unknown'};
    %         end
    %     end
end

disp('done')
toc
%% Load other tables with manually-entered data

tic
load 'analysisTrees/automaticData/wfdsSpatialOffsetTable.mat'
externalTable = wfdsSpatialOffsetTable;
origTableVars = dtab.Properties.VariableNames;
warning('off','MATLAB:table:RowsAddedNewVars')
for i = 1:size(externalTable,1)
    cellName = externalTable.Properties.RowNames{i};
    
    % find if the cell is not already present so we can fill in nans
    % have to put in nan for the missing values because otherwise it'll get filled with 0
    c = strfind(dtab.Properties.RowNames, cellName);
    c2 = [c{:}];
    
    insertRow = externalTable(cellName,:);
    
    if isempty(c2)
        if isKey(cellNameReplacements, cellName)
            cellName = cellNameReplacements(cellName);
        end
        for vi = 1:length(origTableVars)
            varName = origTableVars{vi};
            if ~strcmp(varName, 'cellType') && isempty(strfind(varName, 'SMS')) && isempty(strfind(varName, 'Contrast')) && isempty(strfind(varName, 'params'))
                insertRow(cellName, varName) = {nan};
            end
        end
    end
    dtab(cellName, insertRow.Properties.VariableNames) = insertRow(1,:);
end

% % clear empties
numericalVarColumns = externalTable.Properties.VariableNames;
for i = 1:size(dtab,1)
    d = dtab{i,numericalVarColumns};
    if all(d == 0)
        dtab(i, numericalVarColumns) = num2cell(nan*zeros(1,length(numericalVarColumns)));
    end
end

%

disp('Loaded external data table')
toc
%% load cell locations & types from cell data files
% change the first line variable if you've added new cells since the last run, 
% since this uses caching to save time

loadCellDataFiles = true; 

numCells = size(dtab, 1);
cellNames = dtab.Properties.RowNames;

warning('off','MATLAB:table:RowsAddedNewVars')

% cellLocationsAndTypes = table();
if loadCellDataFiles
    
    disp('Begin loading cell locations and types from files')
    tic
    for ci = 1:numCells
        load([ANALYSIS_FOLDER 'cellData' filesep cellNames{ci} '.mat']); %load cellData
        loc = cellData.location;
        if ~isempty(loc)
            dtab{cellNames{ci}, {'location_x', 'location_y', 'eye'}} = loc;
        else
            dtab{cellNames{ci}, {'location_x', 'location_y', 'eye'}} = [nan, nan, nan];
        end
        
        typ = cellData.cellType;
        dtab{cellNames{ci}, 'cellType'} = {typ};
        
        tags = cellData.tags;
        if isKey(tags, 'QualityRating')
            qr = str2double(tags('QualityRating'));
        else
            qr = nan;
        end
        dtab{cellNames{ci}, 'QualityRating'} = {qr};
    end
    
    cellLocationsAndTypes = dtab(:,{'cellType','location_x', 'location_y', 'eye', 'QualityRating'});
    save('analysisTrees/automaticData/cellLocationsAndTypes', 'cellLocationsAndTypes');
    disp('Done')
    toc
    
else
    load('analysisTrees/automaticData/cellLocationsAndTypes');
    cellNames = dtab.Properties.RowNames;
    
    dtab(:, {'cellType','location_x', 'location_y', 'eye','QualityRating'}) = cellLocationsAndTypes(cellNames,{'cellType','location_x', 'location_y', 'eye','QualityRating'});
end
%% Finish up the number vars

dtab = sortrows(dtab, 'RowNames');
cellNames = dtab.Properties.RowNames;
selectWfdsOn = ~cellfun(@isempty, strfind(dtab{:,'cellType'}, 'ON WFDS'));
selectWfdsOff = ~cellfun(@isempty, strfind(dtab{:,'cellType'}, 'OFF WFDS'));
selectControl = ~(selectWfdsOn | selectWfdsOff);
selectOtherDS = ~cellfun(@isempty, strfind(dtab{:,'cellType'}, 'ON-OFF DS transient'));

%% Save data table
% Change the save file name if desired

save('analysisTrees/automaticData/wfds_data_table', 'dtab','selectWfdsOn','selectWfdsOff','selectControl','selectOtherDS','numCells','cellNames');
%% Initial numbers

fprintf('Total count: %g\n', numCells)
fprintf('ON WFDS: %g\n', sum(selectWfdsOn))
fprintf('ON WFDS: %g\n', sum(selectWfdsOff))
fprintf('Non WFDS: %g\n', sum(selectControl))
fprintf('Other DS: %g\n', sum(selectOtherDS))