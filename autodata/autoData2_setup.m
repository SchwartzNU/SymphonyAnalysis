global ANALYSIS_FOLDER;
cellNamesListLocation = [ANALYSIS_FOLDER 'Projects' filesep 'F mini On/cellNames.txt'];
% cellNamesListLocation = [ANALYSIS_FOLDER 'Projects' filesep 'currentProject/cellNames.txt'];

% set this to [] if no external table
externalTableFilenames = {'analysisTrees/automaticData/externalCellDataTable','externalCellDataTable';
                          'analysisTrees/automaticData/dendritePolygonDatabaseAutodata', 'dendritePolygonDatabaseAutodata';
                          'analysisTrees/automaticData/spatialOnOffOffsetTable','spatialOnOffOffsetTable'};

% output save location, set to [] to not save
outputSaveFilename = 'analysisTrees/automaticData/autodata_fmonproject';


warning('off', 'MATLAB:table:RowsAddedExistingVars')

%% load filter/analysis list
filterFileNames = {'analysisTrees/automaticData/filter light step CA.mat';
    'analysisTrees/automaticData/filter sms mean0 CA.mat';
    'analysisTrees/automaticData/filter sms meanHigh CA.mat';
    'analysisTrees/automaticData/filter drifting texture CA.mat';
    'analysisTrees/automaticData/filter drifting gratings CA.mat';
    'analysisTrees/automaticData/filter sms WC -60.mat';
    'analysisTrees/automaticData/filter sms WC 20.mat';
    'analysisTrees/automaticData/filter moving bar 2000 narrow CA.mat';
    'analysisTrees/automaticData/filter moving bar 1000 narrow CA.mat';
    'analysisTrees/automaticData/filter moving bar 500 narrow CA.mat';
    'analysisTrees/automaticData/filter moving bar 250 narrow CA.mat';
    'analysisTrees/automaticData/filter light step WC -60.mat';
    'analysisTrees/automaticData/filter light step WC 20.mat';
    'analysisTrees/automaticData/filter contrast CA.mat';
    };

% 1 for single params (Light step on spike count mean), 0 for vectors (spike count by spot size), 2 for extracting params for a curve
treeVariableModes = [1,0,0,1,1,0,0,1,1,1,1,2,2,0]; 

paramsByTree = {{'spikeCount_stimInterval_mean', 'spikeCount_afterStim_mean'};
    {'spikeCount_stimInterval','spikeCount_afterStim','ONSETrespDuration'};
    {'spikeCount_stimInterval','spikeCount_afterStim','ONSETrespDuration'};
    {'spikeCount_stimAfter500ms_mean','spikeCount_stimAfter500ms_DSI', 'spikeCount_stimAfter500ms_DSang','spikeCount_stimAfter500ms_OSI', 'spikeCount_stimAfter500ms_OSang', 'spikeCount_stimAfter500ms_DVar'};
    {'F1amplitude_mean','F1amplitude_DSI','F1amplitude_DSang','F1amplitude_OSI','F1amplitude_OSang','F1amplitude_DVar'}
    {'stimInterval_charge','ONSET_peak'};
    {'stimInterval_charge','ONSET_peak'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'spikeCount_stimInterval_mean','spikeCount_stimInterval_DSI', 'spikeCount_stimInterval_DSang','spikeCount_stimInterval_OSI', 'spikeCount_stimInterval_OSang', 'spikeCount_stimInterval_DVar'};
    {'params'};
    {'params'};
    {'ONSETspikes','ONSETlatency'};};
paramsTypeNames = {'LS_sp','SMS_mean0_sp','SMS_meanHigh_sp','DrifTex_sp','DrifGrat_sp','SMS_ex','SMS_in','MB2000','MB1000','MB500','MB250','LS_params_ex','LS_params_in','Contrast_sp'};
paramsColumnNames = {{'LS_ON_sp','LS_OFF_sp'};
    {'SMS_mean0_spotSize_sp','SMS_mean0_onSpikes','SMS_mean0_offSpikes','SMS_mean0_onDuration'};
    {'SMS_meanHigh_spotSize_sp','SMS_meanHigh_onSpikes','SMS_meanHigh_offSpikes','SMS_meanHigh_onDuration'};
    {'DrifTex_mean_sp','DrifTex_DSI_sp','DrifTex_DSang_sp','DrifTex_OSI_sp','DrifTex_OSang_sp','DrifTex_DVar_sp'};
    {'DrifGrat_mean_sp','DrifGrat_DSI_sp','DrifGrat_DSang_sp','DrifGrat_OSI_sp','DrifGrat_OSang_sp','DrifGrat_DVar_sp'};
    {'SMS_spotSize_ex','SMS_charge_ex','SMS_peak_ex'};
    {'SMS_spotSize_in','SMS_charge_in','SMS_peak_in'};
    {'MB_2000_mean_sp','MB_2000_DSI_sp','MB_2000_DSang_sp','MB_2000_OSI_sp','MB_2000_OSang_sp','MB_2000_DVar_sp'};   
    {'MB_1000_mean_sp','MB_1000_DSI_sp','MB_1000_DSang_sp','MB_1000_OSI_sp','MB_1000_OSang_sp','MB_1000_DVar_sp'};
    {'MB_500_mean_sp','MB_500_DSI_sp','MB_500_DSang_sp','MB_500_OSI_sp','MB_500_OSang_sp','MB_500_DVar_sp'};
    {'MB_250_mean_sp','MB_250_DSI_sp','MB_250_DSang_sp','MB_250_OSI_sp','MB_250_OSang_sp','MB_250_DVar_sp'};
    {'LS_ON_params_ex'};
    {'LS_ON_params_in'};
    {'Contrast_contrastVal_sp','Contrast_onSpikes','Contrast_onLatency'};};
%%
analyses = table();
dtabColumns = table();

for fi = 1:length(filterFileNames)
    fname = filterFileNames{fi};
    load(fname, 'filterData','filterPatternString','analysisType');
    analyses{fi,'filterFileName'} = {fname};
    analyses{fi,'analysisType'} = {analysisType};
    
    epochFilt = SearchQuery();
    for i=1:size(filterData,1)
        if ~isempty(filterData{i,1})
            epochFilt.fieldnames{i} = filterData{i,1};
            epochFilt.operators{i} = filterData{i,2};

            value_str = filterData{i,3};
            if isempty(value_str)
                value = [];
            elseif strfind(value_str, ',')
                z = 1;
                r = value_str;
                while ~isempty(r)
                    [token, r] = strtok(r, ',');
                    value{z} = strtrim(token);
                    z=z+1;
                end
            elseif isletter(value_str(1)) % call it char if the first entry is a char
                value = value_str;
            else
                value = str2num(value_str); %#ok<ST2NM>
            end

            epochFilt.values{i} = value;
        end
    end
    epochFilt.pattern = filterPatternString;
    analyses{fi,'epochFilt'} = epochFilt;
    
    % Make columns table
    columnNames = paramsColumnNames{fi};
    for ci = 1:length(columnNames)
        independent = [];
        
        if ci == 1 && treeVariableModes(fi) == 0 % pull off the first column to use as the independent
            ctype = 'vector';
        else
        
            switch treeVariableModes(fi)
                case 1 % single values
                    ctype = 'single';
                case 0 % vectors
                    ctype = 'vector';
                    independent = columnNames(1);
                case 2 % extracted params
                    ctype = 'vector';
            end
        end
        dtabColumns{columnNames{ci}, {'type','independent'}} = {ctype, independent};
    end
    dtabColumns{[paramsTypeNames{fi} '_dataset'],{'type'}} = {'dataset'};
    
        
end

analyses.treeVariableMode = treeVariableModes';
analyses.params = paramsByTree;
analyses.columnNames = paramsColumnNames;
analyses.paramsTypeNames = paramsTypeNames';
numAnalyses = size(analyses, 1);

dtabColumns{'cellType', 'type'} = {'string'};
dtabColumns{'location_x', 'type'} = {'single'};
dtabColumns{'location_y', 'type'} = {'single'};
dtabColumns{'eye', 'type'} = {'single'};
dtabColumns{'QualityRating', 'type'} = {'single'};
