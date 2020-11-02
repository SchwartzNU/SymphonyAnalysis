classdef LabDataGUI < handle
    %GUI for curating epoch data from single cells
    
    properties
        labData = LabData();
        fullCellList = {};
        fullCellDataList = {};
        curCellData = [];
        curCellName = '';
        curCellType = '';
        cellTypeNames = [];
    end
    
    properties (Hidden)
        fig
        handles
        guiTree
        rootNode
        epochFilter = SearchQuery();
        cellFilter = SearchQuery();
        selectedCellName = '';
        curDataSets = {};
        curPrefsMap = [];
        mergedCells = [];
        allEpochKeys = [];
        allCellTags = [];
        cellTags = containers.Map;
        cellData_folder = '';
        labData_fname = '';
        projFolder = '';
        projName = '';
        
        curTag = '';
        curTagVal = '';
        tempAnswer = false
        cellNameChoice = '';
    end
    
    properties (Hidden, Constant)
        operators = {' ','==','>','<','>=','<=','~='};
        iconpath = [matlabroot filesep 'toolbox' filesep 'matlab' filesep 'icons' filesep 'greencircleicon.gif'];
    end
    
    methods
        function obj = LabDataGUI(folder_name)
            %todo: figure out how to organize directory structure for
            %different projects / labData structures
            global ANALYSIS_FOLDER
            global PREFERENCE_FILES_FOLDER
            global SYNC_TO_SERVER
            
            if nargin == 0
                folder_name = '';
            end
            if isempty(folder_name)
                folder_name = uigetdir([ANALYSIS_FOLDER 'Projects/'],'Choose project folder');
            end
            if folder_name == 0
                return
            end
            obj.projFolder = [folder_name filesep];
            folderParts = strsplit(folder_name, filesep);
            obj.projName = folderParts{end};
            obj.cellData_folder = [ANALYSIS_FOLDER 'cellData' filesep];
            
            
            obj.labData.clearContents();
            disp('Initializing cells');
            
            %copy newer versions of local cellData files to server
            if SYNC_TO_SERVER
%                syncLocalCellDataToServer();
            end
            
            %read in CellTags.txt file
            fid = fopen([PREFERENCE_FILES_FOLDER filesep 'CellTags.txt']);
            fline = 'temp';
            while ~isempty(fline)
                fline = fgetl(fid);
                if isempty(fline) || (isscalar(fline) && fline < 0)
                    break;
                end
                curVals = [];
                [curTagName, rem] = strtok(fline);
                while ~isempty(rem)
                    [cval, rem] = strtok(rem);
                    cval = strtrim(cval);
                    curVals = strvcat(curVals, cval);
                end
                obj.cellTags(curTagName) = curVals;
            end
            fclose(fid);
            
            obj.buildUIComponents();
            obj.loadCellNames();
            try % this will error when displays are weird
                obj.loadTree();
            catch
                disp('loadTree stumbled on multi-display configuration. Resize the window to continue');
            end
            obj.initializeEpochFilterTable();
            obj.initializeCellFilterTable();
            obj.initializeCellTypeAndAnalysisMenus();
        end
        
        function buildUIComponents(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['LabDataGUI: ' obj.projName], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ...
                'Position', [0 0.85*bounds(1,4), 0.65*bounds(1,3), 0.8*bounds(1,4)], ...
                'ResizeFcn', @(uiobj,evt)obj.resizeWindow);
            
            %main grid layout
            L_mainGrid = uiextras.GridFlex('Parent', obj.fig);
            
            %Panels
            L_cellsPanel = uiextras.VBox('Parent', L_mainGrid);
            obj.handles.L_cellTypesPanel = uiextras.BoxPanel('Parent', L_mainGrid, ...
                'Title', 'Cell Types      ', ...
                'Units', 'pixels', ... %so that uitree can be resized inside it
                'FontSize', 12);
            L_cellInfoPanel = uiextras.BoxPanel('Parent', L_mainGrid, ...
                'Title', 'Cell information      ', ...                
                'FontSize', 12);
            L_filterPanel = uiextras.BoxPanel('Parent', L_mainGrid, ...
                'Title', 'Filter Construction      ', ...
                'FontSize', 12);
            
            %set layput for main grid
            set(L_mainGrid, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Padding', 5, ...
                'Spacing', 10, ...
                'ColumnSizes', [-3 -2], ...
                'RowSizes', [-3 -2]);
            
            %Cells panel
            %Upper half: cells and data sets
            L_cellsAndDataSets = uiextras.VBox('Parent', L_cellsPanel);
            L_cellsAndDataSetsBoxes = uiextras.HBox('Parent', L_cellsAndDataSets);
            L_cellsAndDataSetsButtonsR1 = uiextras.HButtonBox('Parent', L_cellsAndDataSets);
            L_cellsAndDataSetsButtons = uiextras.HButtonBox('Parent', L_cellsAndDataSets);
            
            %Cells list box
            obj.handles.L_cells = uiextras.BoxPanel('Parent', L_cellsAndDataSetsBoxes, ...
                'Title', 'All cells      ', ...
                'FontSize', 12, ...
                'Padding', 5);
            obj.handles.allCellsListbox = uicontrol('Style', 'listbox', ...
                'Parent', obj.handles.L_cells, ...
                'FontSize', 12, ...
                'String', {'cell 1', 'cell 2', 'cell 3'}, ...
                'Callback', @(uiobj,evt)obj.cellSelectedFcn);
            
            %Cells buttons_row1
            obj.handles.cellDataCurator_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtonsR1, ...
                'FontSize', 12, ...
                'String', 'Cell Data Curator', ...
                'Callback', @(uiobj,evt)obj.openCellDataCurator());
            obj.handles.detectSpikes_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtonsR1, ...
                'FontSize', 12, ...
                'String', 'Detect Spikes', ...
                'Callback', @(uiobj,evt)obj.runDetectSpikes());
            obj.handles.assignCellLocation_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtonsR1, ...
                'FontSize', 12, ...
                'String', 'Assign cell location', ...
                'Callback', @(uiobj,evt)obj.assignCellLocation());
            
            %Cells buttons
            obj.handles.analyzeBrowse_cell_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtons, ...
                'FontSize', 12, ...
                'String', 'Analyze and Browse', ...
                'Callback', @(uiobj,evt)obj.analyzeAndBrowseCell());
            obj.handles.assignCellType_cell_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtons, ...
                'FontSize', 12, ...
                'String', 'Assign cell type', ...
                'Callback', @(uiobj,evt)obj.assignCellType());
            obj.handles.addCellTagSingle_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtons, ...
                'FontSize', 12, ...
                'String', 'Add cell tag', ...
                'Callback', @(uiobj,evt)obj.addCellTagSingle);
            obj.handles.removeCellTagSingle_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtons, ...
                'FontSize', 12, ...
                'String', 'Remove cell tag', ...
                'Callback', @(uiobj,evt)obj.removeCellTagSingle);            
            
            %Set properties for L_cellsAndDataSetsButtons buttonbox
            set(L_cellsAndDataSetsButtonsR1, 'ButtonSize', [160, 35]);
            
            %Set properties for L_cellsAndDataSetsButtons buttonbox
            set(L_cellsAndDataSetsButtons, 'ButtonSize', [160, 35]);
            
            %CellData and datasets boxes
            L_cellDataAndDataSetsBoxes = uiextras.VBox('Parent',  L_cellsAndDataSetsBoxes);
            
            %CellData list box
            L_cellData = uiextras.BoxPanel('Parent', L_cellDataAndDataSetsBoxes, ...
                'Title', 'CellData files      ', ...
                'FontSize', 12, ...
                'Padding', 5);
            obj.handles.cellDataList = uicontrol('Style', 'listbox', ...
                'Parent', L_cellData, ...
                'FontSize', 11, ...
                'HorizontalAlignment', 'left', ...
                'Callback', @(uiobj,evt)obj.loadCurrentCellData, ...
                'String', {''});
            
            %Datasets list box
            L_datasets = uiextras.BoxPanel('Parent', L_cellDataAndDataSetsBoxes, ...
                'Title', 'Data Sets      ', ...
                'FontSize', 12, ...
                'Padding', 5);
            obj.handles.datasetsList = uicontrol('Style', 'edit', ...
                'Enable', 'inactive', ...
                'Max', 20, ...
                'Parent', L_datasets, ...
                'FontSize', 11, ...
                'HorizontalAlignment', 'left', ...
                'String', {''});
            
            %set layout for L_cellDataAndDataSetsBoxes
            set(L_cellDataAndDataSetsBoxes, 'Sizes', [-1 -3]);
            
            %set layout for L_cellsAndDataSetsBoxes
            set(L_cellsAndDataSetsBoxes, 'Sizes', [-1 -1]);
            
            %set layout for L_cellsAndDataSets
            set(L_cellsAndDataSets, 'Sizes', [-1 40 40]);
            
            L_cellTypesTreeAndButtons = uiextras.VBox('Parent', obj.handles.L_cellTypesPanel);
            
            L_empty = uiextras.Empty('Parent', L_cellTypesTreeAndButtons);
            L_cellTypeButtons = uiextras.HButtonBox('Parent', L_cellTypesTreeAndButtons);
            L_cellTypeButtonsR2 = uiextras.HButtonBox('Parent', L_cellTypesTreeAndButtons);
            
            %Cell type panel buttons
            obj.handles.analyzeBrowse_cellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Analyze and Browse', ...
                'Callback', @(uiobj,evt)obj.analyzeAndBrowseCellType);
            obj.handles.changeCellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Assign cell type', ...
                'Callback', @(uiobj,evt)obj.changeCellType);
%             obj.handles.AttachImage_button = uicontrol('Style', 'pushbutton', ...
%                 'Parent', L_cellTypeButtons, ...
%                 'FontSize', 12, ...
%                 'String', 'Attach Image', ...
%                 'Callback', @(uiobj,evt)obj.attachImage);
%             obj.handles.openImage_button = uicontrol('Style', 'pushbutton', ...
%                 'Parent', L_cellTypeButtons, ...
%                 'FontSize', 12, ...
%                 'String', 'Open Image', ...
%                 'Callback', @(uiobj,evt)obj.openImage);
            
            obj.handles.addCellTag_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Add cell tag', ...
                'Callback', @(uiobj,evt)obj.addCellTag);
            obj.handles.removeCellTag_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Remove cell tag', ...
                'Callback', @(uiobj,evt)obj.removeCellTag);
            
            obj.handles.addToProject_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtonsR2, ...
                'FontSize', 12, ...
                'String', 'Add to project', ...
                'Callback', @(uiobj,evt)obj.addToProject);
            obj.handles.removeFromProject_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtonsR2, ...
                'FontSize', 12, ...
                'String', 'Delete from project', ...
                'Callback', @(uiobj,evt)obj.removeFromProject);
            
            %Properties for L_cellTypeButtons
            set(L_cellTypeButtonsR2, ...
                'ButtonSize', [160, 35], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center');
            
            %Properties for L_cellTypeButtons
            set(L_cellTypeButtons, ...
                'ButtonSize', [160, 35], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center');
                        
            %Properties for obj.handles.L_cellTypesPanel
            set(L_cellTypesTreeAndButtons, 'Sizes', [-1 40 40]);
            
            
            %cell info panel
            L_cellInfoBox = uiextras.VBox('Parent',L_cellInfoPanel);
                        
            %Cell tags table
            obj.handles.cellTagsTable = uitable('Parent', L_cellInfoBox, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'Tag', 'Value'}, ...
                'ColumnEditable', logical([0 0]), ...
                'RowName', [], ...
                'Data', cell(12,2));
            
            tablePos = get(obj.handles.cellTagsTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.5);
            col2W = round(tableWidth*.5);
            set(obj.handles.cellTagsTable,'ColumnWidth',{col1W, col2W});
            
            %Cell position table
            obj.handles.cellPositionTable = uitable('Parent', L_cellInfoBox, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'X', 'Y', 'Eye'}, ...
                'ColumnEditable', logical([0 0 0]), ...
                'RowName', [], ...
                'Data', cell(1,3));
                        
            tablePos = get(obj.handles.cellPositionTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.33);
            col2W = round(tableWidth*.33);
            col3W = round(tableWidth*.33);
            set(obj.handles.cellPositionTable,'ColumnWidth',{col1W, col2W, col3W});
            
            %Cell label
            L_cellLabel = uiextras.HBox('Parent',L_cellInfoBox);
            labelText = uicontrol('Parent', L_cellLabel, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'String', 'Online label');
            obj.handles.labelTextVal = uicontrol('Parent', L_cellLabel, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'String', '');
            set(L_cellLabel, 'Sizes', [-1, -1]);
            
            %Cell notes
            L_cellNotes = uiextras.HBox('Parent',L_cellInfoBox);
            notesText = uicontrol('Parent', L_cellNotes, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'String', 'Notes');
            obj.handles.notesTextVal = uicontrol('Parent', L_cellNotes, ...
                'Style', 'edit', ...
                'FontSize', 12, ...
                'String', '', ...
                'Callback', @(uiobj,evt)obj.setCellNotes);
            set(L_cellNotes, 'Sizes', [40, -1]);
            
            set(L_cellInfoBox, 'Sizes', [-1, 60, 40, 40]);
            
            %%%%Filter panel
            L_filterBox = uiextras.VBox('Parent',L_filterPanel);
            
            L_popupGrid = uiextras.Grid('Parent', L_filterBox);
            
            analysisTypeText = uicontrol('Parent', L_popupGrid, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'String', 'Analysis type');
            cellTypeText = uicontrol('Parent', L_popupGrid, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'String', 'Cell type');
            obj.handles.analysisTypePopup = uicontrol('Parent', L_popupGrid, ...
                'Style', 'popupmenu', ....
                'String', ' ', ...
                'Value', 1);
            obj.handles.cellTypePopup = uicontrol('Parent', L_popupGrid, ...
                'Style', 'popupmenu', ....
                'String', ' ', ...
                'Value', 1);
            
            set(L_popupGrid, 'ColumnSizes', [100, -1]);
            
            cellTableText = uicontrol('Parent', L_filterBox, ...
                'Style', 'text', ...
                'String', 'Cell tags', ...
                'FontSize', 12);
            
            obj.handles.cellFilterTable = uitable('Parent', L_filterBox, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'Param', 'Operator', 'Value'}, ...
                'ColumnEditable', logical([1 1 1]), ...
                'CellEditCallback', @(uiobj, evt)obj.cellFilterTableEdit(evt), ...
                'Data', cell(12,3));
            
            L_cellFilterPattern = uiextras.HBox('Parent',L_filterBox);
            cellFilterPatternText = uicontrol('Parent', L_cellFilterPattern, ...
                'Style', 'text', ...
                'String', 'Filter pattern string', ...
                'FontSize', 12);
            obj.handles.cellFilterPatternEdit = uicontrol('Parent', L_cellFilterPattern, ...
                'Style', 'Edit', ...
                'FontSize', 12, ...
                'CallBack', @(uiobj, evt)obj.updateCellFilter);
            set(L_cellFilterPattern, 'Sizes', [150, -1], 'Spacing', 20);
            
            epochPropertiesText = uicontrol('Parent', L_filterBox, ...
                'Style', 'text', ...
                'String', 'Epoch properties', ...
                'FontSize', 12);
            
            obj.handles.epochFilterTable = uitable('Parent', L_filterBox, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'Param', 'Operator', 'Value'}, ...
                'ColumnEditable', logical([1 1 1]), ...
                'CellEditCallback', @(uiobj, evt)obj.epochFilterTableEdit(evt), ...
                'Data', cell(12,3));
            
            %'CellEditCallback', @(uiobj, evt)obj.filterTableEdit(evt), ...
            
            L_epochFilterPattern = uiextras.HBox('Parent',L_filterBox);
            epochFilterPatternText = uicontrol('Parent', L_epochFilterPattern, ...
                'Style', 'text', ...
                'String', 'Filter pattern string', ...
                'FontSize', 12);
            obj.handles.epochFilterPatternEdit = uicontrol('Parent', L_epochFilterPattern, ...
                'Style', 'Edit', ...
                'FontSize', 12, ...
                'CallBack', @(uiobj, evt)obj.updateEpochFilter);
            set(L_epochFilterPattern, 'Sizes', [150, -1], 'Spacing', 20);
            
            L_filterControls = uiextras.HButtonBox('Parent', L_filterBox, ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', ...
                'ButtonSize', [135 35]);
            obj.handles.analyzeBrowseResults_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_filterControls, ...
                'FontSize', 12, ...
                'String', 'Analyze and Browse', ...
                'Callback', @(uiobj,evt)obj.analyzeAndBrowseAcrossCells);
            obj.handles.saveFilterButton = uicontrol('Parent', L_filterControls, ...
                'Style', 'pushbutton', ...
                'String', 'Save filter', ...
                'FontSize', 12, ...
                'Callback', @(uiobj,evt)obj.saveFilter);
            obj.handles.loadFilterButton = uicontrol('Parent', L_filterControls, ...
                'Style', 'pushbutton', ...
                'String', 'Load filter', ...
                'FontSize', 12, ...
                'Callback', @(uiobj,evt)obj.loadFilter);
            obj.handles.loadFilterListButton = uicontrol('Parent', L_filterControls, ...
                'Style', 'pushbutton', ...
                'String', 'Load list & analyze', ...
                'FontSize', 10, ...
                'Callback', @(uiobj,evt)obj.loadFilterList);
                        
            set(L_filterBox, 'Sizes', [-1, 25, -2, 25, 25, -2, 25, 40]);
                                  
        end
        
        function initializeCellTypeAndAnalysisMenus(obj)
            global ANALYSIS_CODE_FOLDER;
            global PREFERENCE_FILES_FOLDER;
            analysisClassesFolder = [ANALYSIS_CODE_FOLDER 'analysisTreeClasses'];
            d = dir(analysisClassesFolder);
            analysisClasses = {};
            z = 1;
            
            for i=1:length(d)
                if ~isempty(strfind(d(i).name, '.m')) && ~strcmp(d(i).name, 'AnalysisTree.m')
                    analysisClasses{z} = strtok(d(i).name, '.');
                    z=z+1;
                end
            end
            %keyboard;
            set(obj.handles.analysisTypePopup, 'String', analysisClasses);
            %            set(obj.handles.cellTypePopup, 'String', ['All', obj.labData.allCellTypes]);
            %read in CellTypeNames.txt file
            fid = fopen([PREFERENCE_FILES_FOLDER filesep 'CellTypeNames.txt']);
            fline = 'temp';
            z=1;
            disp('reading cell type names');
            while ~isempty(fline)
                fline = fgetl(fid);
                if isempty(fline) || (isscalar(fline) && fline < 0)
                    break;
                end
                obj.cellTypeNames{z} = fline;
                z=z+1;
            end
            set(obj.handles.cellTypePopup, 'String', ['All', obj.cellTypeNames]);
            disp('done reading cell type names');
            fclose(fid);
        end
        
        function updateEpochFilterTable(obj)
            %update popupmenu for filter table
            props = [' ', obj.allEpochKeys];
            columnFormat = {props, obj.operators, 'char'};
            set(obj.handles.epochFilterTable,'ColumnFormat',columnFormat)
        end
        
        function updateCellFilterTable(obj)
            %update popupmenu for filter table
            props = [' ', obj.allCellTags];
            columnFormat = {props, obj.operators, 'char'};
            set(obj.handles.cellFilterTable,'ColumnFormat',columnFormat)
        end
                
        function updateCellTagsTable(obj)
            tagNames = obj.curCellData.tags.keys;
            L = length(tagNames);
            D = cell(L,2);
            for i=1:L
                D{i,1} = tagNames{i};
                D{i,2} = obj.curCellData.tags(tagNames{i});
            end
            set(obj.handles.cellTagsTable, 'Data', D);           
        end
        
        function updateCellPositionTable(obj)
            pos = obj.curCellData.location;
            D = cell(1,3);
            if ~isempty(pos)
                D{1,1} = pos(1);
                D{1,2} = pos(2);
                if pos(3) == -1
                    D{1,3} = 'left';
                elseif pos(3) == 1
                    D{1,3} = 'right';
                else
                    D{1,3} = '?';
                end                
            end
            set(obj.handles.cellPositionTable, 'Data', D); 
        end
        
        function setCellNotes(obj)
            obj.curCellData.notes = get(obj.handles.notesTextVal, 'String');
            saveAndSyncCellData(obj.curCellData);
        end
        
        function initializeEpochFilterTable(obj)
            props = [' ', obj.allEpochKeys];
            columnFormat = {props, obj.operators, 'char'};
            set(obj.handles.epochFilterTable,'ColumnFormat',columnFormat);
            
            if isfield(obj.handles, 'epochFilterTable')
                tablePos = get(obj.handles.epochFilterTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.35);
                col2W = round(tableWidth*.20);
                col3W = round(tableWidth*.35);
                set(obj.handles.epochFilterTable,'ColumnWidth',{col1W, col2W, col3W});
            end
        end
        
        function initializeCellFilterTable(obj)
            props = [' ', obj.allCellTags];
            columnFormat = {props, obj.operators, 'char'};
            set(obj.handles.cellFilterTable,'ColumnFormat',columnFormat);
            
            if isfield(obj.handles, 'cellFilterTable')
                tablePos = get(obj.handles.cellFilterTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.35);
                col2W = round(tableWidth*.20);
                col3W = round(tableWidth*.35);
                set(obj.handles.cellFilterTable,'ColumnWidth',{col1W, col2W, col3W});
            end
        end
        
        function cellSelectedFcn(obj)
            cellDataFolder = obj.cellData_folder;
            obj.curCellData = []; %blank so you cannot select the wrong one before the right one is loaded
            
            v = get(obj.handles.allCellsListbox, 'Value');
            obj.curCellName = obj.fullCellList{v};
            
            obj.curDataSets = cellNameToCellDataNames(obj.curCellName);
            dataSetsList = {};
            for i=1:length(obj.curDataSets)
                %curName =[cellDataFolder obj.curDataSets{i} '.mat'];
                %load(curName);
                fprintf('LabDataGUI select cell: ');
                cellData = loadAndSyncCellData(obj.curDataSets{i});
                dataSetsList = [dataSetsList, cellData.savedDataSets.keys];
            end
            
            %set string for cellDataList
            set(obj.handles.cellDataList, 'String', obj.curDataSets);
            set(obj.handles.cellDataList, 'Value', 1);
            
            obj.loadCurrentCellData();
            
            %set string for dataSetsList
            set(obj.handles.datasetsList, 'String', dataSetsList);
            
            %set title of L_cells boxPanel
            set(obj.handles.L_cells, 'Title', ['All cells: Current Cell Type = ' obj.labData.getCellType(obj.curCellName) '      ']);
            
            %set cellTagsTable
            obj.updateCellTagsTable();
            
            %set cell position
            obj.updateCellPositionTable();
            
            %set online label
            if ~iscell(obj.curCellData.get('label'))
                set(obj.handles.labelTextVal, 'String', sprintf('Label: %s', obj.curCellData.get('label')));
            else
                set(obj.handles.labelTextVal, 'String', sprintf('S2 Online Type: %s',obj.curCellData.get('type')));
            end
            %set notes
            set(obj.handles.notesTextVal, 'String', obj.curCellData.notes);
            
            %drawnow;
            %obj.updateDataSets();
        end
        
        %function updateDataSets(obj)
        %   set(obj.handles.datasetsList, 'String', obj.curCellData.savedDataSets.keys);
        %end
        
        function openCellDataCurator(obj)
            if ~isempty(obj.curCellData)
                disp('Launching cell data curator GUI');
                CellDataCurator(obj.curCellData);
            end
        end
        
        function runDetectSpikes(obj)
            if ~isempty(obj.curCellData)
                disp('Launching spike detector GUI');
                
                if contains(obj.curCellName, '-Ch2')
                    streamName = 'Amplifier_Ch2';
                else
                    streamName = 'Amplifier_Ch1';
                end
                params = struct();
                params.spikeDetectorMode = 'advanced';
                params.spikeThreshold = -6;
                SpikeDetectorGUI(obj.curCellData, [], params, streamName);
%                 obj.curCellData.detectSpikes();
            end
        end
        
        function analyzeAndBrowseCell(obj)
            disp('Launching analysis GUI');
            set(obj.fig, 'Name', ['LabDataGUI' ' (analyzing cell)']);
            drawnow;
            if ~isempty(obj.curCellName)
                obj.labData.analyzeCells(obj.curCellName);
                tempTree = obj.labData.collectCells(obj.curCellName);
                TreeBrowserGUI(tempTree);
            end
            set(obj.fig, 'Name', ['LabDataGUI: ' obj.projName]);
        end
        
        function analyzeAndBrowseCellType(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            if isempty(selectedNodes)
                disp('Click on cell to refresh epoch list')
            end
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 1 %cell type
                set(obj.fig, 'Name', ['LabDataGUI' ' (analyzing cells)']);
                drawnow;
                if ~isempty(obj.curCellType)
                    obj.labData.analyzeCells(obj.labData.getCellsOfType(obj.curCellType));
                    tempTree = obj.labData.collectCells(obj.labData.getCellsOfType(obj.curCellType));
                    TreeBrowserGUI(tempTree);
                end
                set(obj.fig, 'Name', ['LabDataGUI: ' obj.projName]);
            elseif get(node, 'Depth') == 0 %individual cell
                obj.analyzeAndBrowseCell();
            end
        end
        
        function analyzeAndBrowseAcrossCells(obj)
            %todo: deal with paramsMap here! 3rd argument to collectAnalyss
            %is params struct
            s = get(obj.handles.analysisTypePopup, 'String');
            v = get(obj.handles.analysisTypePopup, 'Value');
            analysisType = s{v};
            s = get(obj.handles.cellTypePopup, 'String');
            v = get(obj.handles.cellTypePopup, 'Value');
            cellType = s{v};
            if strcmp(cellType, 'All')
                cellType = obj.labData.allCellTypes;
            end
            
            if isempty(obj.epochFilter.pattern)
                epochFilt = [];
            else
                epochFilt = obj.epochFilter;
            end
            if isempty(obj.cellFilter.pattern)
                cellFilt = [];
            else
                cellFilt = obj.cellFilter;
            end
            tempTree = obj.labData.collectAnalysis(analysisType, cellType, cellFilt, epochFilt);
            
            TreeBrowserGUI(tempTree);
        end
        
        function loadTree(obj)
            set(obj.fig, 'Name', ['LabDataGUI' ' (loading cell type tree)']);
            drawnow;
            
            obj.rootNode = uitreenode('v0', 1, 'All Cells', obj.iconpath, false);
            
            %add children
            cellCount = 0;
            if ~isempty(obj.labData)
                cellTypeNames = obj.labData.allCellTypes;
                for i=1:length(cellTypeNames);
                    curNamesList = obj.labData.getCellsOfType(cellTypeNames{i});
                    nodeName = [cellTypeNames{i} ': n = ' num2str(length(curNamesList))];
                    cellCount = cellCount + length(curNamesList);
                    newTreeNode = uitreenode('v0', curNamesList, nodeName, obj.iconpath, false);
                    obj.rootNode.add(newTreeNode);
                    for j=1:length(curNamesList)
                        cellName = curNamesList{j};
                        leafNode = uitreenode('v0', cellName, cellName, obj.iconpath, true);
                        newTreeNode.add(leafNode);
                    end
                end
            end
            
            set(obj.rootNode, 'name', ['All cells n = ' num2str(cellCount)]);
            
            %make uitree for cell types
            pos = get(obj.handles.L_cellTypesPanel, 'Position');
            boxW = pos(3);
            boxH = pos(4);
            
            obj.guiTree = uitree('v0', obj.fig, ...
                'Root', obj.rootNode, ...
                'Position', [10 85 boxW - 15 boxH - 100], ...
                'SelectionChangeFcn', @(uiobj, evt)obj.treeSelectionFcn);
            
            set(obj.fig, 'Name', ['LabDataGUI: ' obj.projName]);
            
        end
        
        function treeSelectionFcn(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 1 %cell type
                selectionName = get(node, 'Name');
                obj.curCellType = strtrim(strtok(selectionName, ':'));
                obj.clearCellInformation();
            elseif get(node, 'Depth') == 0 %individual cell
                obj.curCellName = get(node, 'Name');
                %set selection
                ind = strcmp(obj.curCellName, obj.fullCellList);
                set(obj.handles.allCellsListbox, 'Value', find(ind));
                obj.cellSelectedFcn();
            else %all cells
                obj.clearCellInformation();
            end
            
        end
%         
%         function openImage(obj)
%             cellDataFolder = obj.cellData_folder;
%             selectedNodes = get(obj.guiTree, 'SelectedNodes');
%             node = selectedNodes(1);
%             
%             [fname,pathname] = uigetfile({'*.png;*.tiff;*.tif'},'Choose image file');
%             if get(node, 'Depth') == 1 %cell type
%                 %figure out if I want to bother adding this to LabData
%                 %class, not trivial to do so
%             elseif get(node, 'Depth') == 0 %individual cell
%                 %add cellImage to cellData
%                 
%                 load([cellDataFolder filesep obj.curDataSets{1}]);
%                 open(cellData.imageFile);
%             end
%             
%         end
        
%         function attachImage(obj)
%             cellDataFolder = obj.cellData_folder;
%             selectedNodes = get(obj.guiTree, 'SelectedNodes');
%             node = selectedNodes(1);
%             
%             [fname,pathname] = uigetfile({'*.png;*.tiff;*.tif'},'Choose image file');
%             if get(node, 'Depth') == 1 %cell type
%                 %figure out if I want to bother adding this to LabData
%                 %class, not trivial to do so
%             elseif get(node, 'Depth') == 0 %individual cell
%                 %add cellImage to cellData
%                 for i=1:length(obj.curDataSets)
%                     load([cellDataFolder filesep obj.curDataSets{i}]);
%                     cellData.imageFile = fullfile(pathname, fname);
%                     saveAndSyncCellData(obj.curCellData); %save cellData file
%                 end
%             end
%             
%             obj.loadCurrentCellData();
%         end
        
        function loadCurrentCellData(obj)
            cellDataFolder = obj.cellData_folder;
            
            cellDataNames = get(obj.handles.cellDataList, 'String');
            v = get(obj.handles.cellDataList, 'Value');
            curName = cellDataNames{v};
            %keyboard;
            if ~isempty(curName)
                set(obj.fig, 'Name', ['LabDataGUI' ' (loading cellData struct)']);
                drawnow;
                %curName_fixed = [cellDataFolder curName '.mat'];
                %load(curName_fixed);
                fprintf('LabDataGUI load cell: ');
                cellData = loadAndSyncCellData(curName);
                obj.curCellData = cellData;
                set(obj.fig, 'Name', ['LabDataGUI: ' obj.projName]);
            end
            %keyboard;
        end
        
        function saveFilter(obj)
            global ANALYSIS_FOLDER;
            [fname,fpath] = uiputfile([ANALYSIS_FOLDER filesep 'acrossCellFilters' filesep '*.mat'],'Save filter file');
            if ~isempty(fname) %if selected something
                filterData = get(obj.handles.epochFilterTable,'Data');
                filterPatternString = get(obj.handles.epochFilterPatternEdit, 'String');
                s = get(obj.handles.analysisTypePopup, 'String');
                v = get(obj.handles.analysisTypePopup, 'Value');
                analysisType = s{v};
                s = get(obj.handles.cellTypePopup, 'String');
                v = get(obj.handles.cellTypePopup, 'Value');
                cellType = s{v};
                save(fullfile(fpath, fname), 'filterData', 'filterPatternString', 'analysisType', 'cellType');
            end
        end
        
        function loadFilter(obj)
            global ANALYSIS_FOLDER;
            [fname,fpath] = uigetfile([ANALYSIS_FOLDER filesep 'acrossCellFilters' filesep '*.mat'],'Load filter file');
            if ~isempty(fname) %if selected something
                load(fullfile(fpath, fname), 'filterData', 'filterPatternString','analysisType', 'cellType');
                set(obj.handles.epochFilterTable,'Data',filterData);
                set(obj.handles.epochFilterPatternEdit, 'String', filterPatternString);
                s = get(obj.handles.analysisTypePopup, 'String');
                ind = find(strcmp(analysisType, s));
                if isempty(ind)
                    disp(['Analysis type ' analysisType ' not found']);
                else
                    set(obj.handles.analysisTypePopup, 'Value', ind);
                end
                
                s = get(obj.handles.cellTypePopup, 'String');
                ind = find(strcmp(cellType, s));
                if isempty(ind)
                    disp(['Cell type ' cellType ' not found']);
                else
                    set(obj.handles.cellTypePopup, 'Value', ind);
                end
                
                obj.updateEpochFilter();
                obj.updateCellFilter();
            end
        end
        
        function loadFilterList(obj)
            disp(obj.labData.allCellTypes)
            global ANALYSIS_FOLDER;
            [fname,fpath] = uigetfile(ANALYSIS_FOLDER,'Load filter file');
            if ~isempty(fname) %if selected something
                load(fullfile(fpath, fname))
                
                for fi = 1:length(filterFileNames)
                    fname = filterFileNames{fi};
                    fprintf('Loading filter %g of %g, %s\n', fi, length(filterFileNames), fname);
                
                    % load filter
                    load(fname, 'filterData', 'filterPatternString','analysisType', 'cellType');
                                        
                    epochFilt = SearchQuery();
%                     epochFilter.fieldnames = {};
%                     epochFilter.operators = {};
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
                    
                    if strcmp(cellType, 'All')
                        cellType = obj.labData.allCellTypes;
                    end
                    
                    cellFilt = [];

%                     analysisType
%                     epochFilt
                    tempTree = obj.labData.collectAnalysis(analysisType, cellType, cellFilt, epochFilt);
                    
                    % save tree
                    
                    analysisTree = tempTree;
                    
                    sfile = fullfile('analysisTrees/automaticData/treeData/', num2str(fi));
                    save(sfile, 'analysisTree');
                    disp(['Saved analysis tree to ' sfile]);
                    
                end
                disp('Done with all files');
                
            end
        end
        
        
        
        function loadCellNames(obj)
            cellDataFolder = obj.cellData_folder;
            
            set(obj.fig, 'Name', ['LabDataGUI' ' (Reading cellData names)']);
            drawnow;
            
            %read in cellNames folder from project
            fid = fopen([obj.projFolder 'cellNames.txt'], 'r');
            if fid < 0
                errordlg(['Error: cellNames.txt not found in ' obj.projFolder]);
                close(obj.fig);
                return;
            end
            temp = textscan(fid, '%s', 'delimiter', '\n');
            cellNames = temp{1};
            fclose(fid);
            
            cellNamesForDisplay = {};
            allLoadedParts = [];
            for i=1:length(cellNames)
                disp(['Loading ' cellNames{i} ': cell ' num2str(i) ' of ' num2str(length(cellNames))]);
                cellDataNames = cellNameToCellDataNames(cellNames{i});
                
                changedType = false;
                twoCellsAdded = false;
                cellNameParts = textscan(cellNames{i}, '%s', 'delimiter', ',');
                cellNameParts = cellNameParts{1}; %quirk of textscan
                allLoadedParts = [allLoadedParts; cellNameParts];
                %check if 2 channel for any part
                has2amps = false;
                twoAmpInd = 0;
                for j=1:length(cellDataNames)
                    %figure out cellType and add cell to labData
                    %curName = [cellDataFolder cellDataNames{j}];
                    %load(curName); %loads cellData
                    fprintf('LabDataGUI load names: ');
                    cellData = loadAndSyncCellData(cellDataNames{j});
                    if isempty(cellData)
                        disp('Cell Data file not loaded: may be missing');
                        continue;
                    end
                    if cellData.get('Nepochs') > 0
                        if  ~isnan(cellData.epochs(1).get('amp2')) %if 2 amps
                            has2amps = true;
                            twoAmpInd = j;
                        end
                    end
                end
                
                if cellData.get('Nepochs') > 0
                    if has2amps
                        %curName = [cellDataFolder cellDataNames{twoAmpInd}];
                        %load(curName); %loads cellData
                        cellData = loadAndSyncCellData(cellDataNames{twoAmpInd});
                        [ch1Type, ch2Type] = strtok(cellData.cellType, ';');
                        if length(ch2Type)>1
                            ch2Type = ch2Type(2:end);
                        end
                        if ~isempty(cell2mat(strfind(cellNameParts, '-Ch1')))
                            %disp('Found Ch1');
                            cellType = ch1Type;
                        elseif ~isempty(cell2mat(strfind(cellNameParts, '-Ch2')))
                            %disp('Found Ch2');
                            cellType = ch2Type;
                        else %need to add both cells
                            %disp('adding both cells');
                            twoCellsAdded = true;
                            cellType = ch1Type;
                            if isempty(cellType)
                                cellType = 'unclassified';
                                changedType = true;
                            end
                            if sum(strcmp(allLoadedParts, [cellNames{i} '-Ch1'])) == 0
                                obj.labData.addCell([cellNames{i} '-Ch1'], cellType);
                                obj.fullCellList = [obj.fullCellList [cellNames{i} '-Ch1']];
                                cellNamesForDisplay{end+1} = sprintf('%s-Ch1 | %s', cellNames{i}, cellType);
                            end
                            cellType = ch2Type;
                            if isempty(cellType)
                                cellType = 'unclassified';
                                changedType = true;
                            end
                            if sum(strcmp(allLoadedParts, [cellNames{i} '-Ch2'])) == 0
                                obj.labData.addCell([cellNames{i} '-Ch2'], cellType);
                                obj.fullCellList = [obj.fullCellList [cellNames{i} '-Ch2']];
                                cellNamesForDisplay{end+1} = sprintf('%s-Ch2 | %s', cellNames{i}, cellType);
                            end
                        end
                    else
                        cellType = cellData.cellType;
                    end
                    
                    if isempty(cellType)
                        cellType = 'unclassified';
                        changedType = true;
                    end
                    if ~twoCellsAdded
                        %add cell to list
                        obj.fullCellList = [obj.fullCellList cellNames{i}];
                        if cellData.savedDataSets.Count > 0
                            datasetString = sprintf('| %g', length(cellData.savedDataSets));
                        else
                            datasetString = '';
                        end
                        if strcmp(cellType, 'unclassified')
                            cellNamesForDisplay{end+1} = sprintf('%s %s', cellNames{i}, datasetString);
                        else
                            cellNamesForDisplay{end+1} = sprintf('%s | %s %s', cellNames{i}, cellType, datasetString);
                        end
                        
                        obj.labData.addCell(cellNames{i}, cellType);
                    end
                    
                    for j=1:length(cellDataNames)
                        obj.fullCellDataList = [obj.fullCellDataList cellDataNames{j}];
                        %curName = [cellDataFolder cellDataNames{j}];
                        %load(curName); %loads cellData
                        fprintf('LabDataGUI load epoch & cell keys: ');
                        cellData = loadAndSyncCellData(cellDataNames{j});
                        
                        %                     %automatically fix cellData save locations here
                        %                     [~, basename, ~] = fileparts(curName);
                        %                     if ~strcmp(cellData.savedFileName, curName)
                        %                         disp(['Warning: updating save location for ' basename ' to ' curName]);
                        %                         cellData.savedFileName = curName;
                        %                         save(cellData.savedFileName, 'cellData');
                        %                     end
                        if changedType
                            disp('changed type');
                            cellData.cellType = cellType;
                            saveAndSyncCellData(cellData); %save cellData file
                        end
                        
                        %add epoch keys
                        obj.allEpochKeys = [obj.allEpochKeys cellData.getEpochKeysetUnion()];
                        %add cell keys
                        tempKeys = cellData.tags.keys;
                        tempKeys = tempKeys(setdiff(1:length(tempKeys), strcmp(tempKeys, '')));
                        obj.allCellTags = [obj.allCellTags tempKeys];
                        
                    end
                end
            end
            
            obj.allEpochKeys = unique(obj.allEpochKeys);
            obj.allCellTags = unique(obj.allCellTags);
            
            %obj.fullCellDataList
            set(obj.handles.allCellsListbox, 'String', cellNamesForDisplay);
            
            obj.updateEpochFilterTable();
            
            set(obj.fig, 'Name', ['LabDataGUI: ' obj.projName]);
        end
        
        function nameChoiceOk(obj)
            obj.tempAnswer = true;
            s = get(obj.handles.dlg_cellTypePopup, 'String');
            v = get(obj.handles.dlg_cellTypePopup, 'value');
            temp = s{v};
            if strcmp(temp, 'New cell type')
                obj.cellNameChoice = get(obj.handles.newTypeEdit, 'String');
            else
                obj.cellNameChoice = s{v};
            end
            delete(obj.handles.nameChoiceFig)
        end
        
        function nameChoiceCancel(obj)
            obj.tempAnswer = false;
            obj.cellNameChoice = '';
            delete(obj.handles.nameChoiceFig)
        end
        
        function changeCellType(obj)
            cellDataFolder = obj.cellData_folder;
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 1 %cell type
                %answer = inputdlg(['Rename '  obj.curCellType ' to: '] ,'Rename cell type');
                bounds = screenBounds;
                obj.handles.nameChoiceFig = dialog('Name', 'Choose cell type', ...
                    'Position', [bounds(3)/2-150, bounds(4)/2, 300, 200]);
                obj.handles.dlg_cellTypePopup = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                    'Style', 'popupmenu', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.75, 0.9, 0.2], ...
                    'String', [obj.cellTypeNames, 'New cell type']);
                
                newTypeText = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                    'Style', 'text', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.5, 0.2, 0.2], ...
                    'String', 'New name:');
                
                obj.handles.newTypeEdit = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                    'Style', 'edit', ...
                    'units', 'normalized', ...
                    'position', [0.3, 0.5, 0.65, 0.2], ...
                    'String', '');
                
                ok_button = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                    'Style', 'pushbutton', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.05, 0.3, 0.25], ...
                    'String', 'Ok', ...
                    'Callback', @(uiobj,evt)obj.nameChoiceOk);
                
                cancel_button = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                    'Style', 'pushbutton', ...
                    'units', 'normalized', ...
                    'position', [0.65, 0.05, 0.3, 0.25], ...
                    'String', 'Cancel', ...
                    'Callback', @(uiobj,evt)obj.nameChoiceCancel);
                
                %L_nameChoice = uiextras.VBox('Parent', nameChoiceFig);
                
                waitfor(obj.handles.nameChoiceFig);
                if ~obj.tempAnswer, return; end
                
                if ~isempty(obj.tempAnswer)
                    %reset name for each cell in cellData
                    curCells = get(node, 'Value');
                    cellTypeName = obj.cellNameChoice;
                    for c=1:length(curCells)
                        cellDataNames = cellNameToCellDataNames(curCells(c).toCharArray');
                        for i=1:length(cellDataNames)
                            %curName = [cellDataFolder cellDataNames{i} '.mat'];
                            %load(curName);
                            fprintf('LabDataGUI change cell type: ');
                            cellData = loadAndSyncCellData(cellDataNames{i});
                            %keyboard;
                            if ~isnan(cellData.epochs(1).get('amp2')) %if 2 amps
                                if strfind(cellData.cellType, ';')
                                    [cell1Name, cell2Name] = strtok(cellData.cellType, ';');
                                    cell2Name = cell2Name(2:end);
                                    %keyboard;
                                    if strfind(curCells(c), [cellDataNames{i} '-Ch2']) %name for second cell
                                        cellData.cellType = [cell1Name ';' cellTypeName];
                                    else
                                        cellData.cellType =  [cellTypeName ';' cell2Name];
                                    end
                                else
                                    if strfind(curCells(c), [cellDataNames{i} '-Ch2']) %name for second cell
                                        cellData.cellType = [' ;' cellTypeName];
                                    else
                                        cellData.cellType =  [cellTypeName '; '];
                                    end
                                end
                            else
                                cellData.cellType = cellTypeName;
                            end
                            saveAndSyncCellData(cellData) %save cellData file
                        end
                    end
                    %update labData structure
                    if isempty(obj.labData.getCellsOfType(obj.cellNameChoice)) %new type, so just change name
                        obj.labData.renameType(obj.curCellType, obj.cellNameChoice);
                    else %merge types
                        obj.labData.mergeCellTypes(obj.curCellType, obj.cellNameChoice)
                    end
                    obj.loadTree();
                end
            elseif get(node, 'Depth') == 0 %individual cell
                obj.assignCellType();
            end
        end
        
        function assignCellLocation(obj)
            answer = inputdlg('Enter cell location', '[X, Y, whichEye(L=-1,R=+1]', 1, {'[0 0 -1]'});
            loc = str2num(answer{1});
            if isempty(loc)|| length(loc)==3  %empty position to clear it
                cellDataNames = cellNameToCellDataNames(obj.curCellName);
                for i=1:length(cellDataNames)
                    load([obj.cellData_folder filesep cellDataNames{i}]);
                    %assuming one amp for now (TODO: deal with two???)
                    cellData.location = loc;
                    saveAndSyncCellData(cellData) %save cellData file
                    loadCurrentCellData(obj)
                end
            else
               errordlg('Three element vector required'); 
            end
        end
        
        function assignCellType(obj)
            cellDataFolder = obj.cellData_folder;
            bounds = screenBounds;
            obj.handles.nameChoiceFig = dialog('Name', 'Choose cell type', ...
                'Position', [bounds(3)/2-150, bounds(4)/2, 300, 200]);
            obj.handles.dlg_cellTypePopup = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                'Style', 'popupmenu', ...
                'units', 'normalized', ...
                'position', [0.05, 0.75, 0.9, 0.2], ...
                'String', [obj.cellTypeNames, 'New cell type']);
            
            newTypeText = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                'Style', 'text', ...
                'units', 'normalized', ...
                'position', [0.05, 0.5, 0.2, 0.2], ...
                'String', 'New name:');
            
            obj.handles.newTypeEdit = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                'Style', 'edit', ...
                'units', 'normalized', ...
                'position', [0.3, 0.5, 0.65, 0.2], ...
                'String', '');
            
            ok_button = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                'Style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.05, 0.05, 0.3, 0.25], ...
                'String', 'Ok', ...
                'Callback', @(uiobj,evt)obj.nameChoiceOk);
            
            cancel_button = uicontrol('Parent', obj.handles.nameChoiceFig, ...
                'Style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.65, 0.05, 0.3, 0.25], ...
                'String', 'Cancel', ...
                'Callback', @(uiobj,evt)obj.nameChoiceCancel);
            
            %L_nameChoice = uiextras.VBox('Parent', nameChoiceFig);
            
            waitfor(obj.handles.nameChoiceFig);
            if ~obj.tempAnswer, return; end
            
            cellTypeName = obj.cellNameChoice;
            
            cellDataNames = cellNameToCellDataNames(obj.curCellName);
            for i=1:length(cellDataNames)
                load([cellDataFolder filesep cellDataNames{i}]);
                if ~isnan(cellData.epochs(1).get('amp2')) %if 2 amps
                    if strfind(cellData.cellType, ';')
                        [cell1Name, cell2Name] = strtok(cellData.cellType, ';');
                        cell2Name = cell2Name(2:end);
                        if strfind(obj.curCellName, [cellDataNames{i} '-Ch2']) %name for second cell
                            cellData.cellType = [cell1Name ';' cellTypeName];
                        else
                            cellData.cellType =  [cellTypeName ';' cell2Name];
                        end
                    else
                        if strfind(obj.curCellName, [cellDataNames{i} '-Ch2']) %name for second cell
                            cellData.cellType = [' ;' cellTypeName];
                        else
                            cellData.cellType =  [cellTypeName '; '];
                        end
                    end
                else
                    cellData.cellType = cellTypeName;
                end
                %keyboard;
                saveAndSyncCellData(cellData) %save cellData file
                loadCurrentCellData(obj)
                %keyboard;
                
                %update labData structure
                if isempty(obj.labData.getCellType(obj.curCellName))
                    obj.labData.addCell(obj.curCellName, cellTypeName);
                else
                    obj.labData.moveCell(obj.curCellName, cellTypeName);
                end
                obj.loadTree();
                %obj.initializeCellTypeAndAnalysisMenus();
            end
        end
        
        function addToProject(obj)
            global ANALYSIS_FOLDER;
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
            elseif get(node, 'Depth') == 1 %cell type
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellName = get(node,'name');
                cellNames{1} = cellName;
            end
            
            cellData_proj_folder = uigetdir([ANALYSIS_FOLDER filesep 'Projects'], 'Choose project folder');
            %add to cellNames text file, creating it if necessary
            if ~exist([cellData_proj_folder filesep 'cellNames.txt'], 'file')
                fid = fopen([cellData_proj_folder filesep 'cellNames.txt'], 'w');
            else
                fid = fopen([cellData_proj_folder filesep 'cellNames.txt'], 'a');
            end
            for i=1:length(cellNames)
                fprintf(fid, '%s\n', cellNames{i});
            end
            fclose(fid);
        end
        
        function removeFromProject(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
            elseif get(node, 'Depth') == 1 %cell type
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellName = get(node,'name');
                cellNames{1} = cellName;
            end
            
            fid = fopen([obj.projFolder 'cellNames.txt'], 'r');
            temp = textscan(fid, '%s', 'delimiter', '\n');
            cellNames_old = temp{1};
            fclose(fid);
            cellNames_new = setdiff(cellNames_old,cellNames);
            
            fid = fopen([obj.projFolder 'cellNames.txt'], 'w');
            for i=1:length(cellNames_new)
                fprintf(fid, '%s\n', cellNames_new{i});
            end
            fclose(fid);
            
            %reload labData
            obj.fullCellList = {};
            obj.fullCellDataList = {};
            obj.labData.clearContents();
            obj.loadCellNames();
            obj.loadTree;
        end
        
        function clearCellInformation(obj)
            %set cellTagsTable
            set(obj.handles.cellTagsTable, 'Data', cell(12,2));
            
            %set cell position
            set(obj.handles.cellPositionTable, 'Data', cell(1,3));
            
            %set online label
            set(obj.handles.labelTextVal, 'String', '');
            
            %set notes
            set(obj.handles.notesTextVal, 'String', '');
        end
        
        function addCellTag(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; cellNameToCellDataNames(cellNames{i})];
                end
            elseif get(node, 'Depth') == 1 %cell type
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; cellNameToCellDataNames(cellNames{i})];
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellName = get(node,'name');
                cellDataNames = cellNameToCellDataNames(cellName);
            end
            
            %choose the tag to add with a dialog box
            bounds = screenBounds;
            obj.handles.cellTagFig = dialog('Name', 'Choose cell tag', ...
                'Position', [bounds(3)/2-150, bounds(4)/2, 300, 200]);
            
            obj.handles.dlg_cellTagsPopup = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'popupmenu', ...
                'units', 'normalized', ...
                'position', [0.05, 0.6, 0.4, 0.3], ...
                'String', obj.cellTags.keys, ...
                'Callback', @(uiobj,evt)obj.onTagSelection);
            
            obj.handles.dlg_tagValuesPopup = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'popupmenu', ...
                'units', 'normalized', ...
                'position', [0.5, 0.6, 0.4, 0.3], ...
                'String', ' ');
            
            ok_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.05, 0.05, 0.3, 0.25], ...
                'String', 'Ok', ...
                'Callback', @(uiobj,evt)obj.tagChoiceOk);
            
            cancel_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.65, 0.05, 0.3, 0.25], ...
                'String', 'Cancel', ...
                'Callback', @(uiobj,evt)obj.tagChoiceCancel);
            
            obj.onTagSelection();
            
            waitfor(obj.handles.cellTagFig)
            %waiting for figure to be deleted
            
            if obj.tempAnswer
                for i=1:length(cellDataNames)
                    load([obj.cellData_folder filesep cellDataNames{i} '.mat']); %loads cellData
                    cellData.tags(obj.curTag) = obj.curTagVal;
                    saveAndSyncCellData(cellData) %save cellData file
                end
            end
        end
        
        function addCellTagSingle(obj)
            %choose the tag to add with a dialog box
            bounds = screenBounds;
            obj.handles.cellTagFig = dialog('Name', 'Choose cell tag', ...
                'Position', [bounds(3)/2-150, bounds(4)/2, 300, 200]);
            
            obj.handles.dlg_cellTagsPopup = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'popupmenu', ...
                'units', 'normalized', ...
                'position', [0.05, 0.6, 0.4, 0.3], ...
                'String', obj.cellTags.keys, ...
                'Callback', @(uiobj,evt)obj.onTagSelection);
            
            obj.handles.dlg_tagValuesPopup = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'popupmenu', ...
                'units', 'normalized', ...
                'position', [0.5, 0.6, 0.4, 0.3], ...
                'String', ' ');
            
            ok_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.05, 0.05, 0.3, 0.25], ...
                'String', 'Ok', ...
                'Callback', @(uiobj,evt)obj.tagChoiceOk);
            
            cancel_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                'Style', 'pushbutton', ...
                'units', 'normalized', ...
                'position', [0.65, 0.05, 0.3, 0.25], ...
                'String', 'Cancel', ...
                'Callback', @(uiobj,evt)obj.tagChoiceCancel);
            
            obj.onTagSelection();
            
            waitfor(obj.handles.cellTagFig)
            %waiting for figure to be deleted
            
            if obj.tempAnswer
                obj.curCellData.tags(obj.curTag) = obj.curTagVal;
                saveAndSyncCellData(obj.curCellData) %save cellData file
            end
        end
         
        function removeCellTag(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; cellNameToCellDataNames(cellNames{i})];
                end
            elseif get(node, 'Depth') == 1 %cell type
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; cellNameToCellDataNames(cellNames{i})];
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellName = get(node,'name');
                cellDataNames = cellNameToCellDataNames(cellName);
            end
            
            tagNames = [];
            for i=1:length(cellDataNames)
                tagNames = [tagNames obj.curCellData.tags.keys;];                
            end
            
            tagNames = unique(tagNames);
            
            %choose the tag to add with a dialog box
            if ~isempty(tagNames)
                bounds = screenBounds;
                obj.handles.cellTagFig = dialog('Name', 'Choose cell tag', ...
                    'Position', [bounds(3)/2-150, bounds(4)/2, 300, 200]);
                
                obj.handles.dlg_cellTagsPopup = uicontrol('Parent', obj.handles.cellTagFig, ...
                    'Style', 'popupmenu', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.6, 0.6, 0.3], ...
                    'String', tagNames);
                                
                ok_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                    'Style', 'pushbutton', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.05, 0.3, 0.25], ...
                    'String', 'Ok', ...
                    'Callback', @(uiobj,evt)obj.tagRemoveChoiceOk);
                
                cancel_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                    'Style', 'pushbutton', ...
                    'units', 'normalized', ...
                    'position', [0.65, 0.05, 0.3, 0.25], ...
                    'String', 'Cancel', ...
                    'Callback', @(uiobj,evt)obj.tagChoiceCancel);
                                
                waitfor(obj.handles.cellTagFig)
                %waiting for figure to be deleted
                
                if obj.tempAnswer
                    disp(['removing tag ' obj.curTag]);
                    for i=1:length(cellDataNames)
                        load([obj.cellData_folder filesep cellDataNames{i} '.mat']); %loads cellData
                        if cellData.tags.isKey(obj.curTag)
                            cellData.tags.remove(obj.curTag);
                            saveAndSyncCellData(cellData);
                        end
                    end
                end
            end
        end
        
        function removeCellTagSingle(obj)            
            tagNames = obj.curCellData.tags.keys;
            
            %choose the tag to add with a dialog box
            if ~isempty(tagNames)
                bounds = screenBounds;
                obj.handles.cellTagFig = dialog('Name', 'Choose cell tag', ...
                    'Position', [bounds(3)/2-150, bounds(4)/2, 300, 200]);
                
                obj.handles.dlg_cellTagsPopup = uicontrol('Parent', obj.handles.cellTagFig, ...
                    'Style', 'popupmenu', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.6, 0.6, 0.3], ...
                    'String', tagNames);
                                
                ok_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                    'Style', 'pushbutton', ...
                    'units', 'normalized', ...
                    'position', [0.05, 0.05, 0.3, 0.25], ...
                    'String', 'Ok', ...
                    'Callback', @(uiobj,evt)obj.tagRemoveChoiceOk);
                
                cancel_button = uicontrol('Parent', obj.handles.cellTagFig, ...
                    'Style', 'pushbutton', ...
                    'units', 'normalized', ...
                    'position', [0.65, 0.05, 0.3, 0.25], ...
                    'String', 'Cancel', ...
                    'Callback', @(uiobj,evt)obj.tagChoiceCancel);
                                
                waitfor(obj.handles.cellTagFig)
                %waiting for figure to be deleted
                
                if obj.tempAnswer
                    disp(['removing tag ' obj.curTag]);
                    obj.curCellData.tags.remove(obj.curTag);
                    saveAndSyncCellData(obj.curCellData);
                end
            end
        end
        
        function onTagSelection(obj)
            s = get(obj.handles.dlg_cellTagsPopup, 'String');
            v = get(obj.handles.dlg_cellTagsPopup, 'Value');
            set(obj.handles.dlg_tagValuesPopup, 'String', obj.cellTags(s{v}));
            set(obj.handles.dlg_tagValuesPopup, 'Value', 1);
        end
                                      
        function tagChoiceOk(obj)
            obj.tempAnswer = true;
            s = get(obj.handles.dlg_cellTagsPopup, 'String');
            v = get(obj.handles.dlg_cellTagsPopup, 'Value');
            obj.curTag = s{v};
            
            s = get(obj.handles.dlg_tagValuesPopup, 'String');
            v = get(obj.handles.dlg_tagValuesPopup, 'Value');
            obj.curTagVal = strtrim(s(v,:));
            
            delete(obj.handles.cellTagFig)
        end
        
        function tagRemoveChoiceOk(obj)
            obj.tempAnswer = true;
            s = get(obj.handles.dlg_cellTagsPopup, 'String');
            v = get(obj.handles.dlg_cellTagsPopup, 'Value');
            obj.curTag = s{v};
            
            delete(obj.handles.cellTagFig)
        end
        
        function tagChoiceCancel(obj)
            obj.tempAnswer = false;
            delete(obj.handles.cellTagFig)
        end        
        
        function cellFilterTableEdit(obj, eventData)
            newData = eventData.EditData;
            rowInd = eventData.Indices(1);
            colInd = eventData.Indices(2);
            D = get(obj.handles.cellFilterTable,'Data');
            
            if strcmp(newData,' ') %blank the row
                D{rowInd,1} = '';
                D{rowInd,2} = '';
                D{rowInd,3} = '';
            else
                D{rowInd,colInd} = newData;
            end
            if colInd == 1 %edited parameter name
                %show unique values
                %vals = obj.cellData.getEpochVals(newData);
                %vals = vals(~isnan_cell(vals));
                %vals = unique(vals);
                D{rowInd,3} = ''; %blank the value
            end
            
            set(obj.handles.cellFilterTable,'Data',D);
            
            %if colInd > 1
                obj.updateCellFilter();
            %end
        end
        
        function epochFilterTableEdit(obj, eventData)
            newData = eventData.EditData;
            rowInd = eventData.Indices(1);
            colInd = eventData.Indices(2);
            D = get(obj.handles.epochFilterTable,'Data');
            
            if strcmp(newData,' ') %blank the row
                D{rowInd,1} = '';
                D{rowInd,2} = '';
                D{rowInd,3} = '';
            else
                D{rowInd,colInd} = newData;
            end
            if colInd == 1 %edited parameter name
                %show unique values
                %vals = obj.cellData.getEpochVals(newData);
                %vals = vals(~isnan_cell(vals));
                %vals = unique(vals);
                D{rowInd,3} = ''; %blank the value
            end
            
            set(obj.handles.epochFilterTable,'Data',D);
            
            %if colInd > 1
                obj.updateEpochFilter();
            %end
        end
        
        function updateCellFilter(obj)
            D = get(obj.handles.cellFilterTable,'Data');
            N = size(D,1);
            if isempty(obj.cellFilter) || isempty(obj.cellFilter.fieldnames)
                previousL = 0;
            else
                previousL = length(obj.cellFilter.fieldnames);
            end
            rowsComplete = true;
            for i=1:N
                if ~isempty(D{i,1}) %change stuff and add stuff
                    obj.cellFilter.fieldnames{i} = D{i,1};
                    obj.cellFilter.operators{i} = D{i,2};
                    value_str = D{i,3};
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
                        value = num2str(value_str); %make all cell tags strings!!! Greg update 2/15/15
                    end
                    if ~isempty(value)
                        obj.cellFilter.values{i} = value;
                    else
                        obj.cellFilter.values{i} = value_str;
                    end
                    if i>previousL
                        pattern_str = get(obj.handles.cellFilterPatternEdit,'String');
                        if previousL == 0 %first condition
                            pattern_str = '@1';
                        else
                            pattern_str = [pattern_str ' && @' num2str(i)];
                        end
                        set(obj.handles.cellFilterPatternEdit,'String',pattern_str);
                    end
                    if isempty(obj.cellFilter.fieldnames{i}) ...
                            || isempty(obj.cellFilter.operators{i}) ...
                            || isempty(obj.cellFilter.values{i})
                        rowsComplete = false;
                    end
                elseif i == previousL %remove last condition
                    obj.cellFilter.fieldnames = obj.cellFilter.fieldnames(1:i-1);
                    obj.cellFilter.operators = obj.cellFilter.operators(1:i-1);
                    obj.cellFilter.values = obj.cellFilter.values(1:i-1);
                    
                    pattern_str = get(obj.handles.cellFilterPatternEdit,'String');
                    pattern_str = regexprep(pattern_str, ['@' num2str(i)], '?');
                    set(obj.handles.cellFilterPatternEdit,'String',pattern_str);
                end
            end
            
            obj.cellFilter.pattern = get(obj.handles.cellFilterPatternEdit,'String');
            if rowsComplete
                %obj.applyFilter();
            end
            if isempty(obj.cellFilter.fieldnames)
                %reset to null filter
                obj.cellFilter = SearchQuery();
                %obj.applyFilter(true);
            end
        end
        
        function updateEpochFilter(obj)
            D = get(obj.handles.epochFilterTable,'Data');
            N = size(D,1);
            if isempty(obj.epochFilter) || isempty(obj.epochFilter.fieldnames)
                previousL = 0;
            else
                previousL = length(obj.epochFilter.fieldnames);
            end
            rowsComplete = true;
            for i=1:N
                if ~isempty(D{i,1}) %change stuff and add stuff
                    obj.epochFilter.fieldnames{i} = D{i,1};
                    obj.epochFilter.operators{i} = D{i,2};
                    value_str = D{i,3};
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
                    if ~isempty(value)
                        obj.epochFilter.values{i} = value;
                    else
                        obj.epochFilter.values{i} = value_str;
                    end
                    if i>previousL
                        pattern_str = get(obj.handles.epochFilterPatternEdit,'String');
                        if previousL == 0 %first condition
                            pattern_str = '@1';
                        else
                            pattern_str = [pattern_str ' && @' num2str(i)];
                        end
                        set(obj.handles.epochFilterPatternEdit,'String',pattern_str);
                    end
                    if isempty(obj.epochFilter.fieldnames{i}) ...
                            || isempty(obj.epochFilter.operators{i}) ...
                            || isempty(obj.epochFilter.values{i})
                        rowsComplete = false;
                    end
                elseif i == previousL %remove last condition
                    obj.epochFilter.fieldnames = obj.epochFilter.fieldnames(1:i-1);
                    obj.epochFilter.operators = obj.epochFilter.operators(1:i-1);
                    obj.epochFilter.values = obj.epochFilter.values(1:i-1);
                    
                    pattern_str = get(obj.handles.epochFilterPatternEdit,'String');
                    pattern_str = regexprep(pattern_str, ['@' num2str(i)], '?');
                    set(obj.handles.epochFilterPatternEdit,'String',pattern_str);
                end
            end
            
            obj.epochFilter.pattern = get(obj.handles.epochFilterPatternEdit,'String');
            if rowsComplete
                %obj.applyFilter();
            end
            if isempty(obj.epochFilter.fieldnames)
                %reset to null filter
                obj.epochFilter = SearchQuery();
                %obj.applyFilter(true);
            end
        end
        
        function resizeWindow(obj)
            %uitree
            if isfield(obj.handles, 'L_cellTypesPanel')
                pos = get(obj.handles.L_cellTypesPanel, 'Position');
                boxW = pos(3);
                boxH = pos(4);
                set(obj.guiTree, 'Position', [10 85 boxW - 15 boxH - 100]);
            end
            
            %epoch filtTable
            if isfield(obj.handles, 'epochFilterTable')
                tablePos = get(obj.handles.epochFilterTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.35);
                col2W = round(tableWidth*.20);
                col3W = round(tableWidth*.35);
                set(obj.handles.epochFilterTable,'ColumnWidth',{col1W, col2W, col3W});
            end
            
            %cell filtTable
            if isfield(obj.handles, 'cellFilterTable')
                tablePos = get(obj.handles.cellFilterTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.35);
                col2W = round(tableWidth*.20);
                col3W = round(tableWidth*.35);
                set(obj.handles.cellFilterTable,'ColumnWidth',{col1W, col2W, col3W});
            end
            
            if isfield(obj.handles, 'cellTagsTable')
                tablePos = get(obj.handles.cellTagsTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.5);
                col2W = round(tableWidth*.5);
                set(obj.handles.cellTagsTable,'ColumnWidth',{col1W, col2W});                
            end
            
            if isfield(obj.handles, 'cellPositionTable')
                tablePos = get(obj.handles.cellPositionTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.33);
                col2W = round(tableWidth*.33);
                col3W = round(tableWidth*.33);
                set(obj.handles.cellPositionTable,'ColumnWidth',{col1W, col2W, col3W});
            end
        end
        
        %function delete(obj)
        %clear('classes');
        %end
    end
    
end