function resultTree = doSingleAnalysis(cellName, analysisClassName, filter)
if nargin < 3
    filter = [];
end

%maybe remove this
%overwrite = true;

global ANALYSIS_FOLDER
global PREFERENCE_FILES_FOLDER

%Open DataSetsAnalyses.txt file that defines the mapping between data set
%names and analysis classes
fid = fopen([PREFERENCE_FILES_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

%find correct row in this table
Nanalyses = length(analysisTable{1});
analysisInd = 0;
for i=1:Nanalyses
    if strcmp(analysisTable{2}{i}, analysisClassName);
        analysisInd = i; 
        break;
    end
end
if analysisInd == 0
    disp(['Error: analysis ' analysisClassName ' not found in DataSetAnalyses.txt']);
    resultTree = [];
    return;
end

%Deal with cell names that include '-Ch1' or '-Ch2'
%cellName_orig = cellName;
params_deviceOnly.deviceName = 'Amplifier_Ch1';
loc = strfind(cellName, '-Ch1');
if ~isempty(loc)
    cellName = cellName(1:loc-1);
end
loc = strfind(cellName, '-Ch2');
if ~isempty(loc)
    cellName = cellName(1:loc-1);
    params_deviceOnly.deviceName = 'Amplifier_Ch2';
end

%set up output tree
resultTree = AnalysisTree;
nodeData.name = ['Single analysis tree: ' cellName ' : ' analysisClassName];
nodeData.device = params_deviceOnly.deviceName;
resultTree = resultTree.set(1, nodeData);

%load cellData
load([ANALYSIS_FOLDER 'cellData' filesep cellName]);
dataSetKeys = cellData.savedDataSets.keys;

for i=1:length(dataSetKeys);
    T = [];
    analyzeDataSet = false;
    curDataSet = dataSetKeys{i};
    if strfind(curDataSet, analysisTable{1}{analysisInd}) %if correct data set type
        %evaluate filter
        if ~isempty(filter)
            filterOut = cellData.filterEpochs(filter.makeQueryString(), cellData.savedDataSets(curDataSet));
            if length(filterOut) == length(cellData.savedDataSets(curDataSet)) %all epochs match filter
                analyzeDataSet = true;
            end
        else
            analyzeDataSet = true;
        end
    end
    if analyzeDataSet
        usePrefs = false;
        if ~isempty(cellData.prefsMapName)
            prefsMap = loadPrefsMap(cellData.prefsMapName);
            [hasKey, keyName] = hasMatchingKey(prefsMap, curDataSet); %loading particular parameters from prefsMap
            if hasKey
                usePrefs = true;
                paramSets = prefsMap(keyName);
                for p=1:length(paramSets)
                    T = [];
                    curParamSet = paramSets{p};
                    load([ANALYSIS_FOLDER 'analysisParams' filesep analysisClassName filesep curParamSet]); %loads params
                    params.deviceName = params_deviceOnly.deviceName;
                    params.parameterSetName = curParamSet;
                    params.class = analysisClassName;
                    params.cellName = cellName;
                    eval(['T = ' analysisClassName '(cellData,' '''' curDataSet '''' ', params);']);
                    T = T.doAnalysis(cellData);
                    
                    if ~isempty(T)
                        resultTree = resultTree.graft(1, T); 
                    end
                end
            end
        end
        if ~usePrefs
            params = params_deviceOnly;
            params.class = analysisClassName;
            params.cellName = cellName;
            eval(['T = ' analysisClassName '(cellData,' '''' curDataSet '''' ', params);']);
            T = T.doAnalysis(cellData);
            
            if ~isempty(T)
                resultTree = resultTree.graft(1, T); 
            end
        end
        
        
        %         if overwrite %this block replaces (or adds) this analysis tree to the cell analysis file
%             %try to load existing analysis trees
%             if exist([ANALYSIS_FOLDER 'analysisTrees' filesep cellName_orig '.mat'], 'file')
%                 load([ANALYSIS_FOLDER 'analysisTrees' filesep cellName_orig]);
%                 chInd = cellAnalysisTree.getchildren(1);
%                 treeGrafted = false;
%                 for j=1:length(chInd)
%                     curChildData = cellAnalysisTree.get(chInd(j));
%                     if strcmp(curChildData.name, T.get(1).name) %same analysis and data set
%                         %chop and graft new analysis tree
%                         cellAnalysisTree = cellAnalysisTree.chop(chInd(j));
%                         cellAnalysisTree = cellAnalysisTree.graft(1, T);  
%                         treeGrafted = true;
%                     end
%                 end
%                 if ~treeGrafted
%                     cellAnalysisTree = cellAnalysisTree.graft(1, T); 
%                 end                
%             else %make new file
%                 cellAnalysisTree = AnalysisTree;
%                 nodeData.name = ['Full cell analysis tree: ' cellName];
%                 nodeData.device = params.deviceName;
%                 cellAnalysisTree = cellAnalysisTree.set(1, nodeData);
%                 cellAnalysisTree = cellAnalysisTree.graft(1, T);                 
%             end
%             save([ANALYSIS_FOLDER 'analysisTrees' filesep cellName_orig]);
%         end        

        %T
        %disp(['resultTree length = ' num2str(length(resultTree.getchildren(1)))]);
    end
end

if length(resultTree.Node) == 1 %if nothing found for this cell
    %return empty so this does not get grafted onto anything
    resultTree = [];
end
