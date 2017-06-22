global ANALYSIS_FOLDER;
cellNamesListLocation = [ANALYSIS_FOLDER 'Projects' filesep 'rnaseq/cellNames.txt'];

% set this to [] if no external table
externalTableFilename = [];

% output save location, set to [] to not save
outputSaveFilename = [];


warning('off', 'MATLAB:table:RowsAddedExistingVars')

%% load filter/analysis list
filterFileNames = {};

% 1 for single params (Light step on spike count mean), 0 for vectors (spike count by spot size), 2 for extracting params for a curve
treeVariableModes = []; 

paramsByTree = {};
paramsTypeNames = {};
paramsColumnNames = {};
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
