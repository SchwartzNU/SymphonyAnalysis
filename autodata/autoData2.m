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

%% loop through cells

for ci = 1:numTableCells
    
    fprintf('Processing cell %g of %g\n', ci, numTableCells);
    % make table row
    trow = table();
    
    % make a list of which analyses have been added validly to avoid overwriting earlier
    validAnalyses = false(numAnalyses,1);
    
    %how many cell data in this cell?
    cellNamesInThisCell = cellFileNames{ci};
    cellNamesInThisCell = strsplit(cellNamesInThisCell, ',');
    
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
        end

    
        % loop through filters
        
        for ai = 1:numAnalyses
            
            % check if another cellData for this cell has already given this analysis
            if validAnalyses(ai)
                continue
            end
            
            analysis = analyses(ai,:);

            atree = doSingleAnalysis(cellNamesInThisCell{sci}, analysis{1,'analysisType'}{1}, [], analysis{1,'epochFilt'}, cellData, analysisTable);
            hasValidAnalysis = ~isempty(atree);
            
            paramsColumnNames = analysis{1,'columnNames'}{1};
            params = analysis{1,'params'}{1};
            treeVariableMode = analysis{1,'treeVariableMode'};
            
            if treeVariableMode == 1
                if hasValidAnalysis
                    [~, ~, paramForCells] = allParamsAcrossCells(atree, params);
                    paramForCells(cellfun(@isempty, paramForCells)) = {nan};
                    data = paramForCells';
                    data = cell2mat(data);
                    if size(data,1) > 1 % sometimes the filter catches two data sets... so pick the first one
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
                    end
                else
                    data = cell(1, length(paramsColumnNames));
                end

            end
            
            trow{1,paramsColumnNames} = data;
            validAnalyses(ai) = hasValidAnalysis;
        end
    end


    %% combine table row
    dtab_add(cellNamesInThisCell{1}, trow.Properties.VariableNames) = trow;


end

%% Load external data table for non-automated analyses
tic
if ~isempty(externalTableFilename)
    load(externalTableFilename);
    origTableVars = dtab_add.Properties.VariableNames;
    warning('off','MATLAB:table:RowsAddedNewVars')
    for rowIndex = 1:size(dtab_add,1)
        cellName = dtab_add.Properties.RowNames{rowIndex};

        % find if the external cell is not already present in the table so we can fill in nans
        % have to put in nan for the missing values because otherwise it'll get filled with 0
        if ismember(cellName, externalCellDataTable.Properties.RowNames)
            externalRow = externalCellDataTable(cellName,:);
            dtab_add(cellName, externalRow.Properties.VariableNames) = externalRow(1,:);
        else
            a = size(externalCellDataTable(1,:), 2);
            dtab_add(cellName, externalCellDataTable.Properties.VariableNames) = num2cell(nan(1,a));
        end

%         if ~ismember(cellName, externalCellDataTable.Properties.RowNames)
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

    % clear empties
%     numericalVarColumns = externalCellDataTable.Properties.VariableNames;
%     for tableRow = 1:size(dtab_add,1)
%         d = dtab_add{tableRow, numericalVarColumns};
%         if all(d == 0)
%             dtab_add(tableRow, numericalVarColumns) = num2cell(nan*zeros(1,length(numericalVarColumns)));
%         end
%     end

    %

    disp('Loaded external data table')
    toc
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

if ~isempty(outputSaveFilename)
    save(outputSaveFilename, 'dtab','cellNames','numCells','cellTypeSelect');
    fprintf('saved data to %s \n', outputSaveFilename);
end

fprintf('done processing %g cells\nhave a nice day!\n', numCells)