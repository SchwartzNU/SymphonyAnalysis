global CELL_DATA_MASTER;
global PREFERENCE_FILES_FOLDER;
global SERVER_ROOT;

regenerate_flag = true;

fid = fopen([PREFERENCE_FILES_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisNameTable = textscan(fid, '%s\t%s');
fclose(fid);

% check for server connection
serverConnection = exist(SERVER_ROOT, 'dir') > 0;
if serverConnection
    disp('Found server connection')
else
    error(['No server connection found at ' SERVER_ROOT]);
end
saveFileLocation = [SERVER_ROOT 'cellDatabase' filesep 'cellDatabaseSaveFile.mat'];

%% Get Filters
filterDirectory = [SERVER_ROOT 'cellDatabase' filesep 'filters/'];
filterDirResult = dir([filterDirectory '*.mat']);
filterFileNames = {};
filterTable = table();
warning('off', 'MATLAB:table:RowsAddedExistingVars')

for fi = 1:length(filterDirResult)
    filterShortName = filterDirResult(fi).name;
    filterShortName = filterShortName(1:(end-4));
    fprintf('Loading filter %s \n',filterShortName);
    filterVariableName = regexprep(filterShortName, '[ -]','_');
    load([filterDirectory filterShortName '.mat'], 'filterData','filterPatternString','analysisType');
    filterTable{fi,'filterFileName'} = {filterShortName};
    filterTable{fi,'analysisType'} = {analysisType};
    filterTable{fi,'filterVariableName'} = {filterVariableName};
    
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
    filterTable{fi,'epochFilt'} = epochFilt;
    
end
numFilters = size(filterTable, 1);
fprintf('Loaded %g filters\n', numFilters)

%%  Get Cells

D = dir([CELL_DATA_MASTER '*.mat']);
%D = dir([CELL_DATA_FOLDER '*.mat']);

% 
% if ismac
%     cellDataNames = struct2cell(D.name); %this will be different on windows - see doc ls
%     cellDataNames = cellDataNames(1,:);
%     % cellDataNames = cellDataNames(1:(end-1)); %why ditch last one???
% elseif ispc
%     cellDataNames = struct2cell(cellDataNames);
%     cellDataNames = cellDataNames(1,:);
% end

cellNames = cell(length(D), 1);
modTimes = cell(length(D), 1);
for i=1:length(D)
    cellNames{i} = D(i).name;
    modTimes{i} = datetime( D(i).date, 'InputFormat','dd-MMM-yyyy HH:mm:ss');
end

numCells = length(cellNames);
fprintf('%g cells found\n', numCells);

%% Process cells

load(saveFileLocation, 'updateTime', 'cellDataTable');
if regenerate_flag
    cellDataTable = table();
end

tic
for ci = 1:numCells
    cellName = cellNames{ci};   
    
    if ~regenerate_flag && (modTimes{ci} < datetime(updateTime))
        %fprintf('Skipping %g/%g %s\n', ci, numCells, cellName);
    else %if modified since last update or regenerating
        trow = table();
        fprintf('Processing %g/%g %s\n', ci, numCells, cellName);
        %     trow{1, 'cellName'} = {cellName};        
        try            
            load([CELL_DATA_MASTER cellName]); %load cellData
            %cellData = c.cellData;
        catch
            fprintf('Error loading %s\n', cellName);
            continue
        end
        
        % add basic info from cellData
        loc = cellData.location;
        if ~isempty(loc)
            trow{1, {'location_x', 'location_y', 'eye'}} = loc;
        else
            trow{1, {'location_x', 'location_y', 'eye'}} = [nan, nan, nan];
        end
        typ = cellData.cellType;
        trow{1, 'cellType'} = {typ};
        
        tags = cellData.tags;
        if isKey(tags, 'QualityRating')
            qr = str2double(tags('QualityRating'));
        else
            qr = nan;
        end
        trow{1, 'QualityRating'} = qr;
        
        if isKey(tags, 'Genotype')
            g = tags('Genotype');
        else
            g = nan;
        end
        trow{1, 'Genotype'} = {g};
        
        trow{1, {'Month','Day','Year','Rig','cellNum'}} = {str2double(cellName(1:2)), str2double(cellName(3:4)), str2double(cellName(5:6)), cellName(7), str2double(cellName(9:end))};
        
        for fi = 1:numFilters
            analysis = filterTable(fi,:);
            filterName = analysis.filterFileName;
            epochFilter = analysis.epochFilt;
            analysisType = analysis.analysisType;
            
            try
                [hasCorrectDataSet, ~] = doSingleAnalysis(cellName, analysisType, [], epochFilter, cellData, analysisNameTable, true);
                if isempty(hasCorrectDataSet)
                    hasCorrectDataSet = false;
                end
                trow{1,analysis.filterVariableName} = hasCorrectDataSet;
            catch
                warning(['analysis failed :' analysisType{1}]);
                %             analysisType
                %             epochFilter
                %             filterName
                %             cellData
                continue
            end
        end
        cellDataTable(cellName,:) = trow;
    end
end

%updateTime = clock();
updateTime = datetime('now');

save(saveFileLocation, 'cellDataTable', 'filterTable', 'updateTime');

disp('done')
toc