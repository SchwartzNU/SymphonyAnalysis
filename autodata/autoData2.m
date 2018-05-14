% dataExtractionGeneral
global PREFERENCE_FILES_FOLDER
global CELL_DATA_FOLDER;
fid = fopen([PREFERENCE_FILES_FOLDER 'DataSetAnalyses.txt'], 'r');
analysisTable = textscan(fid, '%s\t%s');
fclose(fid);

%% load cell list

f = fopen(cellNamesListLocation,'r');
cellFileNames = textscan(f,'%s');
cellFileNames = cellFileNames{1};
fclose(f);


%% make full table
dtab_add = table();
numTableCells = length(cellFileNames);
% numTableCells = 10;

%% loop through cells
analysisIndices = 1:numAnalyses;
% analysisIndices = [2,5,6];

for ci = 1:numTableCells
    
    fprintf('Processing cell %g of %g\n', ci, numTableCells);
    % make table row
    trow = table();
    
    % make a list of which analyses have been added validly to avoid overwriting earlier
    validAnalyses = false(numAnalyses,1);
    
    %how many cell data in this cell?
    cellNamesInThisCell = cellFileNames{ci};
    cellNamesInThisCell = strsplit(cellNamesInThisCell, ',');
    
    % ignore multichannel cells for the moment, since they are complicated
    if ~isempty(strfind(cellNamesInThisCell{1}, 'Ch'))
        continue
    end
    
    for sci = 1:length(cellNamesInThisCell)
        
        c = load([CELL_DATA_FOLDER cellNamesInThisCell{sci} '.mat']); %load cellData
        cellData = c.cellData;
        
        % add basic info from cellData
        if sci == 1 % only use first file for this data
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
                g = '';
            end
            trow{1, 'Genotype'} = {g};

            % modify cell data if needed
%             if strcmp(typ, 'F-mini OFF')
%                 cellData.tags('Genotype') = 'PV';
%                 cellData.tags.values
%                 saveAndSyncCellData(cellData);
%             end
        end

        
        % loop through filters
        
        for ai = analysisIndices
            
            % check if another cellData for this cell has already given this analysis
            if validAnalyses(ai)
                continue
            end
            
            analysis = analyses(ai,:);

            [atree, dataSet] = doSingleAnalysis(cellNamesInThisCell{sci}, analysis{1,'analysisType'}{1}, [], analysis{1,'epochFilt'}, cellData, analysisTable);
            hasValidAnalysis = ~isempty(atree);
            
            paramsColumnNames = analysis{1,'columnNames'}{1};
            params = analysis{1,'params'}{1};
            treeVariableMode = analysis{1,'treeVariableMode'};
            paramsTypeName = analysis{1, 'paramsTypeNames'};
            
            if treeVariableMode == 1
                if hasValidAnalysis
                    [~, ~, paramForCells] = allParamsAcrossCells(atree, params);
                    paramForCells(cellfun(@isempty, paramForCells)) = {nan};
                    data = paramForCells';
                    data = cell2mat(data);
                    if size(data,1) > 1 % sometimes the filter catches multiple data sets... so pick the first one
                        data = data(1,:);
                    end
                else
                    data = nan*zeros(1, length(paramsColumnNames));
                end
                
            elseif treeVariableMode == 0
                if hasValidAnalysis
                    data = extractVectorOverSplitParamFromSingleCellTree(atree, params);
                else
                    data = cell(1, length(paramsColumnNames)); 
                end
                    
            elseif treeVariableMode == 2
                if hasValidAnalysis
                    data = extractLightStepParamsFromTree(atree, false);
                    if ~isempty(data)
                        data = data(1,3);
                    else
                        data = cell(1, length(paramsColumnNames));
                    end
                else
                    data = cell(1, length(paramsColumnNames));
                end
                
            elseif treeVariableMode == 3 % single vector param (like model coefs), like 1 except has [] fill
                if hasValidAnalysis
                    [~, ~, paramForCells] = allParamsAcrossCells(atree, params);
                    paramForCells(cellfun(@isempty, paramForCells)) = {[]};
                    data = paramForCells';
%                     data = cell2mat(data);
%                     data = data{1}
                    if size(data,1) > 1 % sometimes the filter catches multiple data sets... so pick the last one
                        data = data(end,:);
                    end
                else
                    data = cell(1, length(paramsColumnNames));
                end
            end
            trow{1,paramsColumnNames} = data;
            trow{1,[paramsTypeName{1} '_dataset']} = {dataSet};
            validAnalyses(ai) = hasValidAnalysis;
        end
    end


    %% combine table row
    dtab_add(cellNamesInThisCell{1}, trow.Properties.VariableNames) = trow;


end

%% Load external data table for non-automated analyses
tic
if ~isempty(externalTableFilenames)
    for ti = 1:length(externalTableFilenames)
        externalTableFilename = externalTableFilenames{ti, 1};
        fprintf('Loading external table %s \n', externalTableFilename);
        S = load(externalTableFilename);
        externalTable = S.(externalTableFilenames{ti, 2});
        origTableVars = dtab_add.Properties.VariableNames;
        externalRow = [];
        warning('off','MATLAB:table:RowsAddedNewVars')
        
        
        % loop through all cells in current table and check if they are in the external table
        for rowIndex = 1:size(dtab_add,1)
            cellName = dtab_add.Properties.RowNames{rowIndex};

            
            if ismember(cellName, externalTable.Properties.RowNames)
%                 fprintf('%s cell in external table\n', cellName)
                externalRow = externalTable(cellName,:);
                
                % if this column from external table adds a column to the table, first init the row with nans
                for vi = 1:length(externalRow.Properties.VariableNames)
                    externalVarName = externalRow.Properties.VariableNames{vi};
                    if ~ismember(externalVarName, dtab_add.Properties.VariableNames)
                        dtab_add(:, externalVarName) = num2cell(nan*zeros(1,size(dtab_add, 1)));
                    end
                end
                
                
                dtab_add(cellName, externalRow.Properties.VariableNames) = externalRow(1,:);
            end

    %         if ~ismember(cellName, externalTable.Properties.RowNames)
    %             for vi = 1:length(origTableVars)
    %                 varName = origTableVars{vi};
    % 
    %                 if strcmp(varName, 'cellType')
    %                     externalRow{cellName, varName} = {''};
    %                 elseif isempty(strfind(varName, 'SMS')) && isempty(strfind(varName, 'Contrast')) && isempty(strfind(varName, 'params'))
    %                     externalRow(cellName, varName) = {nan};
    %                 end
    %             end
    %         end

        end

%         % clear empties
%         numericalVarColumns = externalTable.Properties.VariableNames;
%         for tableRow = 1:size(dtab_add,1)
%             d = dtab_add{tableRow, numericalVarColumns};
%             if all(d == 0)
%                 dtab_add(tableRow, numericalVarColumns) = num2cell(nan*zeros(1,length(numericalVarColumns)));
%             end
%         end

        %
        
        if ~isempty(externalRow)
            for vi = 1:length(externalRow.Properties.VariableNames)
                dtabColumns{externalRow.Properties.VariableNames{vi}, 'type'} = {'single'};
            end
        end
        
        disp('Loaded external data table')
        toc
    end
end

%% combine Additional rows with current table
if exist('dtab','var')
    for rowIndex = 1:size(dtab_add,1)
        cellName = dtab_add.Properties.RowNames{rowIndex};
        addRow = dtab_add(cellName,:);
        addTableVars = addRow.Properties.VariableNames;
        
%         for vi = 1:length(addTableVars)
%             varName = addTableVars{vi}
%             
%             if strcmp(varName, 'cellType')
%                 
%             elseif isempty(strfind(varName, 'SMS')) && isempty(strfind(varName, 'Contrast')) && isempty(strfind(varName, 'params'))
%                 addRow(cellName, varName) = {nan};
%             end
%         end        
        
        
        dtab(cellName, addRow.Properties.VariableNames) = addRow(1,:);
    end
else
    dtab = dtab_add;
end

%% process full table

% generate cell select map
% valid = ~cellfun(@isempty, dtab.cellType);
[cellTypes, ia, ic] = unique(dtab.cellType);
cellTypeSelect = containers.Map;
for i = 1:length(cellTypes)
    cellTypeSelect(cellTypes{i}) = ic == i;
end
numCells = size(dtab, 1);
cellNames = dtab.Properties.RowNames;

disp('Running secondary analysis')
autoData_secondary

if ~isempty(outputSaveFilename)
    save(outputSaveFilename, 'dtab','dtabColumns','cellNames','numCells','cellTypeSelect');
    fprintf('saved data to %s \n', outputSaveFilename);
end

fprintf('done processing %g cells\nhave a nice day!\n', numCells)