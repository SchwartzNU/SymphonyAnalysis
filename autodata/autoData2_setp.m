global ANALYSIS_FOLDER;
cellNamesListLocation = [ANALYSIS_FOLDER 'Projects' filesep 'WFDS On and Off and Controls/cellNames.txt'];

%% load filter/analysis list
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
paramsColumnNames = {{'LS_ON_sp','LS_OFF_sp'};
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
%%
analyses = table();
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
            else
                value = str2num(value_str); %#ok<ST2NM>
            end

            epochFilt.values{i} = value;
        end
    end
    epochFilt.pattern = filterPatternString;
    analyses{fi,'epochFilt'} = epochFilt;
end

analyses.treeVariableMode = treeVariableModes';
analyses.params = paramsByTree;
analyses.columnNames = paramsColumnNames;
numAnalyses = size(analyses, 1);