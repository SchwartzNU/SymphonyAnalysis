function cellAnalysisTree = analyzeCell(cellName)
global ANALYSIS_FOLDER
global PREFERENCE_FILES_FOLDER

%Open DataSetsAnalyses.txt file that defines the mapping between data set
%names and analysis classes
fid = fopen([PREFERENCE_FILES_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

%Deal with cell names that include '-Ch1' or '-Ch2'
params.deviceName = 'Amplifier_Ch1';
loc = strfind(cellName, '-Ch1');
if ~isempty(loc)
    cellName = cellName(1:loc-1);
end
loc = strfind(cellName, '-Ch2');
if ~isempty(loc)
    cellName = cellName(1:loc-1);
    params.deviceName = 'Amplifier_Ch2';
end
params_deviceOnly = params;

load([ANALYSIS_FOLDER 'cellData' filesep cellName]);
prefsMap = [];
%if ~isempty(cellData.prefsMapName)
%    prefsMap = loadPrefsMap(cellData.prefsMapName);
%end

dataSetKeys = cellData.savedDataSets.keys;
cellAnalysisTree = AnalysisTree;
nodeData.name = ['Full cell analysis tree: ' cellName];
nodeData.device = params.deviceName;
%could add a class here
cellAnalysisTree = cellAnalysisTree.set(1, nodeData);

Nanalyses = length(analysisTable{1});

for i=1:length(dataSetKeys)
    curDataSet = dataSetKeys{i};
    for j=1:Nanalyses
        T = [];
        dataSetNameResult = strfind(curDataSet, analysisTable{1}{j});
        if dataSetNameResult == 1 % matches the name of an analysis on the first character
            
            curAnalysisClass = analysisTable{2}{j};
            fprintf('Running analysis %s on dataset %s\n', curAnalysisClass, curDataSet)
            usePrefs = false;
            if ~isempty(prefsMap)
                [hasKey, keyName] = hasMatchingKey(prefsMap, curDataSet); %loading particular parameters from prefsMap
                if hasKey
                    usePrefs = true;
                    paramSets = prefsMap(keyName);
                    for p=1:length(paramSets)
                        T = [];
                        curParamSet = paramSets{p};
                        load([ANALYSIS_FOLDER 'analysisParams' filesep curAnalysisClass filesep curParamSet]); %loads params
                        params.deviceName = params_deviceOnly.deviceName;
                        params.parameterSetName = curParamSet;
                        params.class = curAnalysisClass;
                        params.cellName = cellName;                        
                        eval(['T = ' curAnalysisClass '(cellData,' '''' curDataSet '''' ', params);']);
                        T = T.doAnalysis(cellData);
                        
                        if ~isempty(T)
                            cellAnalysisTree = cellAnalysisTree.graft(1, T);
                        end
                    end
                end
            end
            if ~usePrefs
                params = params_deviceOnly;
                params.class = curAnalysisClass;
                params.cellName = cellName;
                eval(['T = ' curAnalysisClass '(cellData,' '''' curDataSet '''' ', params);']);
                
                T = T.doAnalysis(cellData);
                
                if ~isempty(T)
                    cellAnalysisTree = cellAnalysisTree.graft(1, T);
                end
            end
        end
    end
end



