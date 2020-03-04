classdef CellDatabaseGUI < handle
    %GUI for curating epoch data from single cells
    
    properties
        cellDataTable
        filterTable
        currentCellNames
        fig
        handles
    end
    
    methods
        function obj = CellDatabaseGUI()
            global SERVER_ROOT
            serverConnection = exist(SERVER_ROOT, 'dir') > 0;
            if ~serverConnection
                error('no server connection')
            end
            saveFileLocation = [SERVER_ROOT 'cellDatabase' filesep 'cellDatabaseSaveFile.mat'];
            c = load(saveFileLocation);
            disp('Loaded database from server')
            
            updateTime = datetime(c.updateTime);
            elapsedDays = floor(days(datetime(clock) - updateTime));
            elapsedHoursAndMins = hours((datetime(clock) - updateTime) - elapsedDays);
            elapsedHours = floor(hours((datetime(clock) - updateTime) - elapsedDays));
            elapsedMins = floor((elapsedHoursAndMins - elapsedHours) * 60);
            %secSinceUpdate = etime(clock, c.updateTime);
            %elapsedDays = datestr(secSinceUpdate/(24*60*60), 'DD');
            %elapsedHours = datestr(secSinceUpdate/(24*60*60), 'HH');
            
            fprintf('Database was updated %d days, %d hours, %d minutes ago\n',char(elapsedDays), elapsedHours, elapsedMins)
            
            obj.cellDataTable = c.cellDataTable;
            obj.filterTable = c.filterTable;
            obj.currentCellNames = {};
                        
            obj.buildUI();
            
            obj.updateCellFilter();
        end
        
        
        function buildUI(obj)
            
            obj.fig = figure( ...
                'Name',         sprintf('Cell Database GUI: %g cells',size(obj.cellDataTable, 1)), ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none');
            
            obj.handles.mainBox = uix.HBox('Parent', obj.fig);
            obj.handles.selectionBox = uix.VBox('Parent', obj.handles.mainBox);
                        
            obj.handles.filterSelection_panel = uix.BoxPanel('Parent', obj.handles.selectionBox, ...
                'Title', 'Filters       ', ...
                'Padding', 5);
            obj.handles.filterSelection = uicontrol('Style','listbox',...
                'Parent', obj.handles.filterSelection_panel, ...
                'FontSize', 12,...
                'Max', 2, ...
                'Value', [], ...
                'String', obj.filterTable.filterVariableName, ...
                'Callback', @(a,b)obj.updateCellFilter());
            
            cellTypes = unique(obj.cellDataTable.cellType);
            obj.handles.cellTypeSelection_panel = uix.BoxPanel('Parent', obj.handles.selectionBox, ...
                'Title', 'Cell Types       ', ...
                'Padding', 5);
            obj.handles.cellTypeSelection = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellTypeSelection_panel, ...
                'FontSize', 12,...
                'Max', 2, ...
                'Value', [], ...
                'String', cellTypes, ...
                'Callback', @(a,b)obj.updateCellFilter());
            
            
            obj.handles.actionBox = uix.VBox('Parent', obj.handles.mainBox);
            
            obj.handles.cellNameList_panel = uix.BoxPanel('Parent', obj.handles.actionBox, ...
                'Title', 'Filtered Cell Names       ', ...
                'FontSize', 16, ...
                'Padding', 5);
            obj.handles.cellNameList = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellNameList_panel, ...
                'FontSize', 12,...
                'Max', 2, ...
                'Value', [], ...
                'String', {''});            
            
            obj.handles.generateProjectButton = uicontrol('Style', 'pushbutton', ...
            'Parent', obj.handles.actionBox, ...
            'String', 'Generate Project', ...
            'Callback', @(a,b)obj.generateProject());
        
            uicontrol('Style', 'pushbutton', ...
            'Parent', obj.handles.actionBox, ...
            'String', 'Checkout Raw Data', ...
            'Callback', @(a,b)obj.checkoutRawData());
        
            uicontrol('Style', 'pushbutton', ...
            'Parent', obj.handles.actionBox, ...
            'String', 'Checkout Cell Data', ...
            'Callback', @(a,b)obj.checkoutCellData());
        
            obj.handles.actionBox.Heights = [-1, 30, 30, 30];
            obj.handles.mainBox.Widths = [-1,200];
        end
        
        function updateCellFilter(obj)
            
            filterSelectedIndices = obj.handles.filterSelection.Value;
            
            cellsHaveDataSet = [];
            if isempty(filterSelectedIndices)
                cellsHaveDataSet = ones(1, size(obj.cellDataTable,1)); % no filters => all cells OK
            else
                for fi = 1:length(filterSelectedIndices)
                    filterIndex = filterSelectedIndices(fi);
                    filterVariableName = obj.filterTable.filterVariableName{filterIndex};
                    cellsHaveDataSet(fi,:) = obj.cellDataTable.(filterVariableName);
                end
            end
            
            cellsHaveDataSet = all(cellsHaveDataSet, 1);
            cellSelect = cellsHaveDataSet;
            
            % look for cell types
            cellTypeIndices = obj.handles.cellTypeSelection.Value;
            cellsAreRightType = [];
            if ~isempty(cellTypeIndices)
                cellTypes = obj.handles.cellTypeSelection.String(obj.handles.cellTypeSelection.Value);
                for ci = 1:size(obj.cellDataTable)
                    includeCell = false;
                    for ti = 1:length(cellTypes)
                        ty = obj.cellDataTable.cellType{ci};
                        if strcmp(ty, cellTypes{ti})
                            includeCell = true;
                        end
                    end
                    cellsAreRightType(1,ci) = includeCell;
                end
                cellSelect = all(vertcat(cellsHaveDataSet, cellsAreRightType));
                
            end
            
            
            cellNames = obj.cellDataTable.Properties.RowNames;
            cellNames = cellNames(cellSelect);
            obj.currentCellNames = cellNames;
            
            obj.handles.cellNameList.String = cellNames;
            obj.handles.cellNameList.Value = [];
            
            obj.handles.cellNameList_panel.Title = sprintf('Filtered Cell Names (%g)     ', length(cellNames)); 
        end

        function mergedCells = processMergedCells(obj)
            % this function expands each cell name entry to include all merged cells,
            % then uses 'unique' to remove the duplicates
            
            global PREFERENCE_FILES_FOLDER
            fid = fopen([PREFERENCE_FILES_FOLDER 'MergedCells.txt']);
            fline = 'temp';
            mergedCells = obj.currentCellNames;
            zi = 1; % track output index
            while ~isempty(fline)
                fline = fgetl(fid);
                if isempty(fline)
                    break;
                end
                if fline == -1
                    break;
                end
               
                names = strsplit(fline,'\t');
                
                for ci = 1:length(mergedCells)
                    newName = mergedCells{ci};
                    for mi = 1:length(names)
                        if strcmp(names{mi}, mergedCells{ci})
                        	newName = strjoin(names,',');
                        end
                    end
                    mergedCells{ci} = newName;
                end
            end
            mergedCells = unique(mergedCells);
        end
        
        function generateProject(obj)
            global ANALYSIS_FOLDER
            if isempty(obj.currentCellNames)
                warning('No cells match all criteria')
                return
            end
            
            mergedCells = processMergedCells(obj);
            
            projectName = inputdlg('Project name for ');
            if isempty(projectName)
                return
            end
            projectName = projectName{1};
            if ~isempty(projectName)
                dirName = [ANALYSIS_FOLDER 'Projects' filesep projectName];
                if exist(dirName, 'dir')
                    warning('Project already exists')
                    return
                end
                mkdir(dirName);
                fileId = fopen([dirName filesep 'cellNames.txt'], 'w');
                for r = 1:length(mergedCells)
                    fprintf(fileId, '%s\n', mergedCells{r});
                end
                fclose(fileId);
                fprintf('Wrote %g cells (after merging) to %s\n', length(mergedCells), dirName);
            end
        end
        
        function checkoutRawData(obj)
            if ~isempty(obj.currentCellNames)
                checkoutRawDataForProject(obj.currentCellNames)
            end
        end
        
        function checkoutCellData(obj)
            if ~isempty(obj.currentCellNames)
                checkoutCellDataForProject(obj.currentCellNames)
            end
        end        
        
    end
    
end