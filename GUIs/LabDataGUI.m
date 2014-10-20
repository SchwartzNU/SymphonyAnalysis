classdef LabDataGUI < handle
    %GUI for curating epoch data from single cells
    
    properties
        labData
        fullCellList = {};
        fullCellDataList = {};
        curCellData = [];
        curCellName = '';
        curCellType = '';
        curLabDataSet = '';
        cellTypeNames = [];
    end
    
    properties (Hidden)
        fig
        handles
        guiTree
        rootNode
        filter = SearchQuery();
        selectedCellName = '';
        curDataSets = {};
        curPrefsMap = [];
        mergedCells = [];
        allEpochKeys = [];
        allCellTags = [];
        cellTags = containers.Map;
        cellData_folder = '';
        labData_fname = '';
        
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
        function obj = LabDataGUI()
            %todo: figure out how to organize directory structure for
            %different projects / labData structures
            global ANALYSIS_FOLDER
            global PREFERENCE_FILES_FOLDER
            folder_name = '';
            pre_part = '';
            while isempty(folder_name) || isempty(pre_part)
                folder_name = uigetdir(ANALYSIS_FOLDER,'Choose cellData folder');
                [pre_part,suff_part] = strtok(folder_name, '_');
                if ~strfind(pre_part, 'cellData')
                    pre_part = '';
                end
            end
            suff_part = suff_part(2:end); %remove leading '_';
            obj.curLabDataSet = suff_part;
            obj.cellData_folder = [ANALYSIS_FOLDER filesep 'cellData_' obj.curLabDataSet filesep];
            obj.labData_fname = [ANALYSIS_FOLDER filesep 'labData_' obj.curLabDataSet '.mat'];

            if exist(obj.labData_fname, 'file')
                load(obj.labData_fname); %loads D
                firstLoad = false;
            else
                D = LabData();
                save(obj.labData_fname, 'D');
                firstLoad = true;
                disp('First load: initializing cells');
            end
            obj.labData = D;
            
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
            obj.loadCellNames(firstLoad);
            obj.loadTree();
            obj.initializeEpochFilterTable();
            obj.initializeCellFilterTable();
            obj.initializeCellTypeAndAnalysisMenus();
        end
        
        function buildUIComponents(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['LabDataGUI: ' obj.cellData_folder], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ...
                'Position', [0 0.85*bounds(4), 0.65*bounds(3), 0.8*bounds(4)], ...
                'ResizeFcn', @(uiobj,evt)obj.resizeWindow);
            
            %main grid layout
            L_mainGrid = uiextras.GridFlex('Parent', obj.fig);
            
            %Panels
            L_cellsPanel = uiextras.VBox('Parent', L_mainGrid);
            obj.handles.L_cellTypesPanel = uiextras.BoxPanel('Parent', L_mainGrid, ...
                'Title', 'Cell Types', ...
                'Units', 'pixels', ... %so that uitree can be resized inside it
                'FontSize', 12);
            L_filterPanel = uiextras.BoxPanel('Parent', L_mainGrid, ...
                'Title', 'Filter Construction', ...
                'FontSize', 12);
            L_filterResultsPanel = uiextras.BoxPanel('Parent', L_mainGrid, ...
                'Title', ' ', ...
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
            L_cellsAndDataSetsButtons = uiextras.HButtonBox('Parent', L_cellsAndDataSets);
            
            %Cells list box
            obj.handles.L_cells = uiextras.BoxPanel('Parent', L_cellsAndDataSetsBoxes, ...
                'Title', 'All cells', ...
                'FontSize', 12, ...
                'Padding', 5);
            obj.handles.allCellsListbox = uicontrol('Style', 'listbox', ...
                'Parent', obj.handles.L_cells, ...
                'FontSize', 12, ...
                'String', {'cell 1', 'cell 2', 'cell 3'}, ...
                'Callback', @(uiobj,evt)obj.cellSelectedFcn);
            
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
            obj.handles.cellDataCurator_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtons, ...
                'FontSize', 12, ...
                'String', 'Cell Data Curator', ...
                'Callback', @(uiobj,evt)obj.openCellDataCurator());
            obj.handles.detectSpikes_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsAndDataSetsButtons, ...
                'FontSize', 12, ...
                'String', 'Detect Spikes', ...
                'Callback', @(uiobj,evt)obj.runDetectSpikes());
            
            %Set properties for L_cellsAndDataSetsButtons buttonbox
            set(L_cellsAndDataSetsButtons, 'ButtonSize', [160, 40]);
            
            %CellData and datasets boxes
            L_cellDataAndDataSetsBoxes = uiextras.VBox('Parent',  L_cellsAndDataSetsBoxes);
            
            %CellData list box
            L_cellData = uiextras.BoxPanel('Parent', L_cellDataAndDataSetsBoxes, ...
                'Title', 'CellData files', ...
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
                'Title', 'Data Sets', ...
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
            set(L_cellsAndDataSets, 'Sizes', [-1 50]);
            
            %Lower half: PrefsMaps
            L_prefs = uiextras.VBox('Parent', L_cellsPanel);
            L_prefsBoxes = uiextras.HBox('Parent', L_prefs);
            L_prefsButtons = uiextras.HButtonBox('Parent', L_prefs);
            
            %PrefsMap list box
            L_prefsMapBox = uiextras.BoxPanel('Parent', L_prefsBoxes, ...
                'Title', 'Preferences Map', ...
                'FontSize', 12, ...
                'Padding', 5);
            obj.handles.prefsMapList = uicontrol('Style', 'text', ...
                'Parent', L_prefsMapBox, ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left', ...
                'String', {'MyPrefsMap'});
            
            %PrefsMap elements list box
            L_prefsMapElementsBox = uiextras.BoxPanel('Parent', L_prefsBoxes, ...
                'Title', 'Preference Map Elements', ...
                'FontSize', 12, ...
                'Padding', 5);
            obj.handles.prefsMapElementsListbox = uicontrol('Style', 'listbox', ...
                'Parent', L_prefsMapElementsBox, ...
                'FontSize', 12, ...
                'String', {'SpotsMultiSize_ON', 'SpotsMultiSize_ON', 'MovingBar_ON', 'MovingBar_OFF'});
            
            %set layout for L_prefsBoxes
            set(L_prefsBoxes, 'Sizes', [-1 -1]);
            
            %PrefsMap buttons
            obj.handles.addChangePrefsMap_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_prefsButtons, ...
                'FontSize', 12, ...
                'String', 'Add/Change Pref. Map', ...
                'Callback', @(uiobj,evt)obj.setPrefsMap);
            obj.handles.addPrefElement_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_prefsButtons, ...
                'FontSize', 12, ...
                'String', 'Open Pref. Map', ...
                'Callback',  @(uiobj,evt)obj.openPrefsMap);
            obj.handles.analysisParamsGUI_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_prefsButtons, ...
                'FontSize', 12, ...
                'String', 'Open AnalysisParamsGUI', ...
                'Callback',  @(uiobj,evt)obj.openAnalysisParamsGUI);
            
            %Set properties for L_cellsAndDataSetsButtons buttonbox
            set(L_prefsButtons, 'ButtonSize', [160, 40]);
            
            %set layout for L_cellsPanel
            set(L_cellsPanel, 'Sizes', [-2 -1]);
            
            %set layout for L_cellsAndDataSets
            set(L_prefs, 'Sizes', [-1 50]);
            
            L_cellTypesTreeAndButtons = uiextras.VBox('Parent', obj.handles.L_cellTypesPanel);
            
            L_empty = uiextras.Empty('Parent', L_cellTypesTreeAndButtons);
            L_cellTypeButtons = uiextras.HButtonBox('Parent', L_cellTypesTreeAndButtons);
            L_cellTypeButtons_secondRow = uiextras.HButtonBox('Parent', L_cellTypesTreeAndButtons);
            
            %Cell type panel buttons
            obj.handles.analyzeBrowse_cellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Analyze and Browse', ...
                'Callback', @(uiobj,evt)obj.analyzeAndBrowseCellType);
            obj.handles.changeCellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Change cell type', ...
                'Callback', @(uiobj,evt)obj.changeCellType);
            obj.handles.AttachImage_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Attach Image', ...
                'Callback', @(uiobj,evt)obj.attachImage);
            obj.handles.openImage_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons, ...
                'FontSize', 12, ...
                'String', 'Open Image', ...
                'Callback', @(uiobj,evt)obj.openImage);
            
            %Cell type panel buttons second row
            obj.handles.analyzeBrowse_cellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons_secondRow, ...
                'FontSize', 12, ...
                'String', 'Add to project', ...
                'Callback', @(uiobj,evt)obj.addToCellDataSubfolder);
            obj.handles.analyzeBrowse_cellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons_secondRow, ...
                'FontSize', 12, ...
                'String', 'Delete from project', ...
                'Callback', @(uiobj,evt)obj.removeFromCellDataSubfolder);
            obj.handles.changeCellType_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellTypeButtons_secondRow, ...
                'FontSize', 12, ...
                'String', 'Add cell tag', ...
                'Callback', @(uiobj,evt)obj.addCellTag);
            
            
            %Properties for L_cellTypeButtons
            set(L_cellTypeButtons, ...
                'ButtonSize', [160, 35], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center');
            
            %Properties for L_cellTypeButtons_secondRow
            set(L_cellTypeButtons_secondRow, ...
                'ButtonSize', [160, 35], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center');
            
            %Properties for obj.handles.L_cellTypesPanel
            set(L_cellTypesTreeAndButtons, 'Sizes', [-1 40 40]);
            
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
                'Data', cell(4,3));
            
            L_cellFilterPattern = uiextras.HBox('Parent',L_filterBox);
            cellFilterPatternText = uicontrol('Parent', L_cellFilterPattern, ...
                'Style', 'text', ...
                'String', 'Filter pattern string', ...
                'FontSize', 12);
            obj.handles.cellFilterPatternEdit = uicontrol('Parent', L_cellFilterPattern, ...
                'Style', 'Edit', ...
                'FontSize', 12, ...
                'CallBack', @(uiobj, evt)obj.updateFilter);
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
                'Data', cell(4,3));
                        
            %'CellEditCallback', @(uiobj, evt)obj.filterTableEdit(evt), ...
            
            L_epochFilterPattern = uiextras.HBox('Parent',L_filterBox);
            epochFilterPatternText = uicontrol('Parent', L_epochFilterPattern, ...
                'Style', 'text', ...
                'String', 'Filter pattern string', ...
                'FontSize', 12);
            obj.handles.epochFilterPatternEdit = uicontrol('Parent', L_epochFilterPattern, ...
                'Style', 'Edit', ...
                'FontSize', 12, ...
                'CallBack', @(uiobj, evt)obj.updateFilter);
            set(L_epochFilterPattern, 'Sizes', [150, -1], 'Spacing', 20);            
            
            L_filterControls = uiextras.HButtonBox('Parent', L_filterBox, ...
                'ButtonSize', [100 30], ...
                'Spacing', 20);
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
            %filter results buttons
            
            
            set(L_filterBox, 'Sizes', [-1, 25, -2, 25, 25, -2, 25, 40]);
            
            %filter resutls panel
            L_filterResultsBox = uiextras.Empty('Parent',L_filterResultsPanel);
            %uiextras.VBox('Parent',L_filterResultsPanel);
            %            obj.handles.filterResultsTable =
            %             uitable('Parent', L_filterResultsBox, ...
            %                 'Units',    'pixels', ...
            %                 'FontSize', 11, ...
            %                 'ColumnEditable', logical([0 0]), ...
            %                 'ColumnName', [], ...
            %                 'RowName', [], ...
            %                 'ColumnFormat', {'char', 'char'}, ...
            %                 'Data', cell(7,2), ...
            %                 'TooltipString', 'table for filter results');
            
            
            
            %Set properties for L_filterResultsBox
            % set(L_filterResultsBox, 'Sizes', [-1]);
            
            %Set properties for L_filterResultsButtons buttonbox
            %set(L_filterResultsButtons, 'ButtonSize', [160, 40]);
            
            
        end
        
        function initializeCellTypeAndAnalysisMenus(obj)
            global ANALYSIS_CODE_FOLDER;
            global PREFERENCE_FILES_FOLDER;
            analysisClassesFolder = [ANALYSIS_CODE_FOLDER filesep 'analysisTreeClasses'];
            d = dir(analysisClassesFolder);
            analysisClasses = {};
            z = 1;
            for i=1:length(d)
                if ~isempty(strfind(d(i).name, '.m')) && ~strcmp(d(i).name, 'AnalysisTree.m')
                    analysisClasses{z} = strtok(d(i).name, '.');
                    z=z+1;
                end
            end
            
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
            
            obj.curDataSets = obj.cellNameToCellDataNames(obj.curCellName);
            dataSetsList = {};
            for i=1:length(obj.curDataSets)
                curName =[cellDataFolder filesep obj.curDataSets{i} '.mat'];
                load(curName);
                dataSetsList = [dataSetsList, cellData.savedDataSets.keys];
            end
            
            %set string for cellDataList
            set(obj.handles.cellDataList, 'String', obj.curDataSets);
            set(obj.handles.cellDataList, 'Value', 1);
            
            obj.loadCurrentCellData();
            
            %set string for dataSetsList
            set(obj.handles.datasetsList, 'String', dataSetsList);
            
            %set string for prefsMap box and curPrefsMap map
            set(obj.handles.prefsMapList, 'String', obj.curCellData.prefsMapName);
            if ~isempty(obj.curCellData.prefsMapName)
                obj.curPrefsMap = loadPrefsMap(obj.curCellData.prefsMapName);
            else
                obj.curPrefsMap = [];
            end
            obj.updatePrefsMapElements();
            
            %set title of L_cells boxPanel
            set(obj.handles.L_cells, 'Title', ['All cells: Current Cell Type = ' obj.labData.getCellType(obj.curCellName)]);
            
            %drawnow;
            %obj.updateDataSets();
        end
        
        %function updateDataSets(obj)
        %   set(obj.handles.datasetsList, 'String', obj.curCellData.savedDataSets.keys);
        %end
        
        function openCellDataCurator(obj)
            if ~isempty(obj.curCellData)
                CellDataCurator(obj.curCellData);
            end
        end
        
        function runDetectSpikes(obj)
            if ~isempty(obj.curCellData)
                obj.curCellData.detectSpikes();
            end
        end
        
        function setPrefsMap(obj)
            global ANALYSIS_FOLDER;
            prefsMapSpec = [ANALYSIS_FOLDER filesep 'analysisParams' filesep 'ParameterPrefs' filesep '*.txt'];
            fname = uigetfile(prefsMapSpec, 'Select prefsMap text file');
            if ~isempty(fname)
                obj.curCellData.prefsMapName = fname;
                cellData = obj.curCellData;
                save(obj.curCellData.savedFileName, 'cellData'); %save cellData file
                obj.curPrefsMap = loadPrefsMap(fname);
                set(obj.handles.prefsMapList, 'String', obj.curCellData.prefsMapName);
                obj.updatePrefsMapElements();
            end
        end
        
        function updatePrefsMapElements(obj)
            if ~isempty(obj.curPrefsMap)
                elementList = {};
                k = obj.curPrefsMap.keys;
                for i=1:length(k)
                    curSet = obj.curPrefsMap(k{i});
                    for j=1:length(curSet)
                        curName = [k{i} ':' curSet{j}];
                        elementList = [elementList; curName];
                    end
                end
                set(obj.handles.prefsMapElementsListbox, 'String', elementList);
                set(obj.handles.prefsMapElementsListbox, 'Value', 1);
            else
                set(obj.handles.prefsMapElementsListbox, 'String', '');
                set(obj.handles.prefsMapElementsListbox, 'Value', 0);
            end
        end
        
        function openPrefsMap(obj)
            global ANALYSIS_FOLDER;
            prefsMapFolder = [ANALYSIS_FOLDER filesep 'analysisParams' filesep 'ParameterPrefs'];
            mapName = obj.curCellData.prefsMapName;
            if ~isempty(mapName)
                open([prefsMapFolder filesep mapName]);
            end
        end
        
        function openAnalysisParamsGUI(obj)
            AnalysisParamGUI();
        end
        
        
        function analyzeAndBrowseCell(obj)
            set(obj.fig, 'Name', ['LabDataGUI' ' (analyzing cell)']);
            drawnow;
            if ~isempty(obj.curCellName)
                obj.labData.analyzeCells(obj.curCellName);
                tempTree = obj.labData.collectCells(obj.curCellName);
                TreeBrowserGUI(tempTree);
            end
            set(obj.fig, 'Name', ['LabDataGUI: ' obj.cellData_folder]);
        end
        
        function analyzeAndBrowseCellType(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 1 %cell type
                set(obj.fig, 'Name', ['LabDataGUI' ' (analyzing cells)']);
                drawnow;
                if ~isempty(obj.curCellType)
                    obj.labData.analyzeCells(obj.labData.getCellsOfType(obj.curCellType));
                    tempTree = obj.labData.collectCells(obj.labData.getCellsOfType(obj.curCellType));
                    TreeBrowserGUI(tempTree);
                end
                set(obj.fig, 'Name', ['LabDataGUI: ' obj.cellData_folder]);
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
            
            if isempty(obj.filter.pattern)
                tempTree = obj.labData.collectAnalysis(analysisType, cellType);
            else
                tempTree = obj.labData.collectAnalysis(analysisType, cellType, obj.filter);
            end
            
            TreeBrowserGUI(tempTree);
        end
        
        function loadTree(obj)
            set(obj.fig, 'Name', ['LabDataGUI' ' (loading cell type tree)']);
            drawnow;
            
            obj.rootNode = uitreenode('v0', 1, 'All Cells', obj.iconpath, false);
            
            %add children
            if ~isempty(obj.labData)
                cellTypeNames = obj.labData.allCellTypes;
                for i=1:length(cellTypeNames);
                    curNamesList = obj.labData.getCellsOfType(cellTypeNames{i});
                    nodeName = [cellTypeNames{i} ': n = ' num2str(length(curNamesList))];
                    newTreeNode = uitreenode('v0', curNamesList, nodeName, obj.iconpath, false);
                    obj.rootNode.add(newTreeNode);
                    for j=1:length(curNamesList)
                        cellName = curNamesList{j};
                        leafNode = uitreenode('v0', cellName, cellName, obj.iconpath, true);
                        newTreeNode.add(leafNode);
                    end
                end
            end
            
            %make uitree for cell types
            pos = get(obj.handles.L_cellTypesPanel, 'Position');
            boxW = pos(3);
            boxH = pos(4);
            
            obj.guiTree = uitree('v0', obj.fig, ...
                'Root', obj.rootNode, ...
                'Position', [10 100 boxW - 15 boxH - 130], ...
                'SelectionChangeFcn', @(uiobj, evt)obj.treeSelectionFcn);
            
            set(obj.fig, 'Name', ['LabDataGUI: ' obj.cellData_folder]);
            
        end
        
        function treeSelectionFcn(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 1 %cell type
                selectionName = get(node, 'Name');
                obj.curCellType = strtrim(strtok(selectionName, ':'));
            elseif get(node, 'Depth') == 0 %individual cell
                obj.curCellName = get(node, 'Name');
                %set selection
                ind = strcmp(obj.curCellName, obj.fullCellList);
                set(obj.handles.allCellsListbox, 'Value', find(ind));
                obj.cellSelectedFcn();
            end
            
        end
        
        function openImage(obj)
            cellDataFolder = obj.cellData_folder;
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            [fname,pathname] = uigetfile({'*.png;*.tiff;*.tif'},'Choose image file');
            if get(node, 'Depth') == 1 %cell type
                %figure out if I want to bother adding this to LabData
                %class, not trivial to do so
            elseif get(node, 'Depth') == 0 %individual cell
                %add cellImage to cellData
                
                load([cellDataFolder filesep obj.curDataSets{1}]);
                open(cellData.imageFile);
            end
            
        end
        
        function attachImage(obj)
            cellDataFolder = obj.cellData_folder;
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            [fname,pathname] = uigetfile({'*.png;*.tiff;*.tif'},'Choose image file');
            if get(node, 'Depth') == 1 %cell type
                %figure out if I want to bother adding this to LabData
                %class, not trivial to do so
            elseif get(node, 'Depth') == 0 %individual cell
                %add cellImage to cellData
                for i=1:length(obj.curDataSets)
                    load([cellDataFolder filesep obj.curDataSets{i}]);
                    cellData.imageFile = fullfile(pathname, fname);
                    save([cellDataFolder filesep obj.curDataSets{i}], 'cellData');
                end
            end
            
            obj.loadCurrentCellData();
        end
        
        function loadCurrentCellData(obj)
            cellDataFolder = obj.cellData_folder;
            
            cellDataNames = get(obj.handles.cellDataList, 'String');
            v = get(obj.handles.cellDataList, 'Value');
            curName = cellDataNames{v};
            if ~isempty(curName)
                set(obj.fig, 'Name', ['LabDataGUI' ' (loading cellData struct)']);
                drawnow;
                curName_fixed = [cellDataFolder filesep curName '.mat'];
                load(curName_fixed);
                obj.curCellData = cellData;
                set(obj.fig, 'Name', ['LabDataGUI: ' obj.cellData_folder]);
            end
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
                
                obj.updateFilter();
            end
        end
        
        function loadCellNames(obj, firstLoad)
            global PREFERENCE_FILES_FOLDER
            cellDataFolder = obj.cellData_folder;
            if nargin<2
                firstLoad = false;
            end
            
            set(obj.fig, 'Name', ['LabDataGUI' ' (Reading cellData names)']);
            drawnow;
            
            %read in MergedCells.txt file
            fid = fopen([PREFERENCE_FILES_FOLDER filesep 'MergedCells.txt']);
            fline = 'temp';
            z=1;
            while ~isempty(fline)
                fline = fgetl(fid);
                if isempty(fline)
                    break;
                end
                obj.mergedCells{z} = {};
                [cname, rem] = strtok(fline);
                obj.mergedCells{z} = [obj.mergedCells{z}; cname];
                while ~isempty(rem)
                    [cname, rem] = strtok(rem);
                    cname = strtrim(cname);
                    %rem = strtrim(rem);
                    obj.mergedCells{z} = [obj.mergedCells{z}; cname];
                end
                z=z+1;
            end
            
            d = dir(cellDataFolder);
            
            for i=1:length(d)
                if strfind(d(i).name, '.mat')
                    curName = [cellDataFolder filesep d(i).name];
                    load(curName);
                    
                    if firstLoad
                        disp(['Cell ' num2str(i) ' of ' num2str(length(d))]);
                        if ~isprop(cellData, 'prefsMapName')
                            cellData.prefsMapName = '';
                        end
                        if ~isprop(cellData, 'cellType') || isempty(cellData.cellType)
                            cellData.cellType = 'unclassified';
                        end
                        if ~isprop(cellData, 'imageFile')
                            cellData.imageFile = '';
                        end
                        %                     if isempty(cellData.savedFileName)
                        %                         cellData.savedFileName = ['/Users/Greg/analysis/cellData/' cellData.rawfilename '.mat'];
                        %                     end
                        save(cellData.savedFileName, 'cellData');
                    end
                    
                    basename = strtok(d(i).name,'.mat');
                    if cellData.get('Nepochs') > 0
                        %add epoch keys
                        obj.allEpochKeys = [obj.allEpochKeys cellData.getEpochKeysetUnion()];
                        %add cell keys
                        obj.allCellTags = [obj.allCellTags cellData.tags.keys];
                        
                        if ~isnan(cellData.epochs(1).get('amp2')) %if 2 amps
                            n1 = [basename '-Ch1'];
                            n2 = [basename '-Ch2'];
                            obj.fullCellDataList = [obj.fullCellDataList, n1, n2];
                            obj.fullCellList = [obj.fullCellList obj.cellDataNameToCellName(n1)];
                            obj.fullCellList = [obj.fullCellList obj.cellDataNameToCellName(n2)];
                            %if firstLoad
                            if isempty(obj.labData.getCellType(obj.cellDataNameToCellName(n1)))
                                if ~isempty(obj.cellDataNameToCellName(n1))
                                    ch1Name = strtok(cellData.cellType, ';');
                                    if isempty(ch1Name)
                                        if ~obj.labData.hasCell(obj.cellDataNameToCellName(n1))
                                            obj.labData.addCell(obj.cellDataNameToCellName(n1), 'unclassified');
                                        end
                                    else
                                        if ~obj.labData.hasCell(obj.cellDataNameToCellName(n1))
                                            obj.labData.addCell(obj.cellDataNameToCellName(n1), ch1Name)
                                        end
                                    end
                                end
                                
                                if ~isempty(obj.cellDataNameToCellName(n2))
                                    [~, ch2Name] = strtok(cellData.cellType, ';');
                                    ch2Name = ch2Name(2:end);
                                    if isempty(ch2Name)
                                        if ~obj.labData.hasCell(obj.cellDataNameToCellName(n2))
                                            obj.labData.addCell(obj.cellDataNameToCellName(n2), 'unclassified');
                                        end
                                    else
                                        if ~obj.labData.hasCell(obj.cellDataNameToCellName(n2))
                                            obj.labData.addCell(obj.cellDataNameToCellName(n2), ch2Name)
                                        end
                                    end
                                end
                            end
                            %end
                        else %one amp
                            obj.fullCellDataList = [obj.fullCellDataList, basename];
                            obj.fullCellList = [obj.fullCellList obj.cellDataNameToCellName(basename)];
                            %if firstLoad
                            if isempty(obj.labData.getCellType(obj.cellDataNameToCellName(basename)))
                                name = cellData.cellType;
                                if ~isempty(obj.cellDataNameToCellName(basename))
                                    if isempty(name)
                                        if ~obj.labData.hasCell(obj.cellDataNameToCellName(basename))
                                            obj.labData.addCell(obj.cellDataNameToCellName(basename), 'unclassified');
                                        end
                                    else
                                        if ~obj.labData.hasCell(obj.cellDataNameToCellName(basename))
                                            obj.labData.addCell(obj.cellDataNameToCellName(basename), name);
                                        end
                                    end
                                end
                            end
                            %end
                        end
                    end
                end
            end
            
            obj.allEpochKeys = unique(obj.allEpochKeys);
            obj.allCellTags = unique(obj.allCellTags);
            
            %obj.fullCellDataList
            set(obj.handles.allCellsListbox, 'String', obj.fullCellList);

            obj.updateEpochFilterTable();
            
            %save labData
            D = obj.labData;
            save(obj.labData_fname, 'D'); %save labData
            
            set(obj.fig, 'Name', ['LabDataGUI: ' obj.cellData_folder]);
        end
        
        function cellName = cellDataNameToCellName(obj, cellDataName)
            cellName = cellDataName;
            L = length(obj.mergedCells);
            for i=1:L
                if sum(strcmp(cellName, obj.mergedCells{i}) > 0)
                    if strcmp(cellName, obj.mergedCells{i}{1})
                        curMerge = obj.mergedCells{i};
                        cellName = curMerge{1};
                        for j=2:length(curMerge);
                            cellName = [cellName ', ' curMerge{j}];
                        end
                        break;
                    else
                        cellName = '';
                    end
                end
            end
        end
        
        function cellDataNames = cellNameToCellDataNames(obj, cellName)
            cellDataNames = {};
            [curName, rem] = strtok(cellName, ',');
            curName = strtok(curName, '-Ch');
            cellDataNames{1} = strtrim(curName);
            rem = strtrim(rem);
            while ~isempty(rem)
                [curName, rem] = strtok(rem, ',');
                curName = strtok(curName, '-Ch');
                cellDataNames = [cellDataNames; strtrim(curName)];
                rem = strtrim(rem);
            end
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
                    obj.labData.renameType(obj.curCellType, obj.cellNameChoice);
                    %update labData structure
                    D = obj.labData;
                    save(obj.labData_fname, 'D');
                    obj.loadTree();
                    %obj.initializeCellTypeAndAnalysisMenus();
                    
                    
                    %reset name for each cell in cellData
                    curCells = get(node, 'Value');
                    cellTypeName = obj.cellNameChoice;
                    for c=1:length(curCells)
                        cellDataNames = cellNameToCellDataNames(obj, curCells(c).toCharArray');
                        for i=1:length(cellDataNames)
                            curName = [cellDataFolder filesep cellDataNames{i} '.mat'];
                            load(curName);                            
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
                            save(cellData.savedFileName, 'cellData');
                        end
                    end
                   obj.loadTree(); 
                end                
            elseif get(node, 'Depth') == 0 %individual cell
                obj.assignCellType();
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
            
            cellDataNames = cellNameToCellDataNames(obj, obj.curCellName);
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
                save(cellData.savedFileName, 'cellData');
                loadCurrentCellData(obj)
                
                %update labData structure
                if isempty(obj.labData.getCellType(obj.curCellName))
                    obj.labData.addCell(obj.curCellName, cellTypeName);
                else
                    obj.labData.moveCell(obj.curCellName, cellTypeName);
                end
                D = obj.labData;
                save(obj.labData_fname, 'D');
                obj.loadTree();
                %obj.initializeCellTypeAndAnalysisMenus();
            end
        end
        
        function addToCellDataSubfolder(obj)
            global ANALYSIS_FOLDER;
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; obj.cellNameToCellDataNames(cellNames{i})];                    
                end
            elseif get(node, 'Depth') == 1 %cell type                
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; obj.cellNameToCellDataNames(cellNames{i})];                    
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellName = get(node,'name');
                cellDataNames = obj.cellNameToCellDataNames(cellName);
            end
            
            cellData_proj_folder = uigetdir(ANALYSIS_FOLDER, 'Choose cellData folder');
            for i=1:length(cellDataNames)
                eval(['!ln ' obj.cellData_folder filesep cellDataNames{i} '.mat ' cellData_proj_folder]);
            end            
        end
        
        function removeFromCellDataSubfolder(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; obj.cellNameToCellDataNames(cellNames{i})];                    
                end
            elseif get(node, 'Depth') == 1 %cell type                
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; obj.cellNameToCellDataNames(cellNames{i})];                    
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellNames = get(node,'name');
                cellDataNames = obj.cellNameToCellDataNames(cellNames);
            end
            
            %do the deletion
            if ischar(cellNames) %single cell
                obj.labData.deleteCell(cellNames);
            else %multiple cells
                for i=1:length(cellNames)
                    obj.labData.deleteCell(cellNames{i});
                end
            end
            %get all cell data names to figure out if we can delete this
            %cellData file (if the other channel is not in this project)
            allCellDataNames = [];
            allCellNames = obj.labData.allCellNames();
            for i=1:length(allCellNames)
                allCellDataNames = [allCellNames; obj.cellNameToCellDataNames(allCellNames{i})];
            end
            
            if ischar(cellDataNames)
                if ~strcmp(cellDataNames, allCellDataNames)
                    disp([cellDataNames ' being deleted from project']);
                    eval(['!rm ' obj.cellData_folder cellDataNames '.mat']);
                end
            else
                for i=1:length(cellDataNames)
                    if ~strcmp(cellDataNames{i}, allCellDataNames)
                        disp([cellDataNames{i} ' being deleted from project']);
                        eval(['!rm ' obj.cellData_folder cellDataNames{i} '.mat']);
                    end
                end
            end
            D = obj.labData;
            save(obj.labData_fname, 'D');
            obj.loadTree();                    
        end
        
        function addCellTag(obj)
            selectedNodes = get(obj.guiTree, 'SelectedNodes');
            node = selectedNodes(1);
            
            if get(node, 'Depth') == 2 %All cells
                cellNames = obj.labData.allCellNames();
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; obj.cellNameToCellDataNames(cellNames{i})];                    
                end
            elseif get(node, 'Depth') == 1 %cell type                
                if ~isempty(obj.curCellType)
                    cellNames = obj.labData.getCellsOfType(obj.curCellType);
                end
                cellDataNames = [];
                for i=1:length(cellNames)
                    cellDataNames = [cellDataNames; obj.cellNameToCellDataNames(cellNames{i})];                    
                end
            elseif get(node, 'Depth') == 0 %individual cell
                cellName = get(node,'name');
                cellDataNames = obj.cellNameToCellDataNames(cellName);
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
            
            if obj.tempAnswer
                for i=1:length(cellDataNames)
                    load([obj.cellData_folder filesep cellDataNames{i} '.mat']); %loads cellData
                    cellData.tags(obj.curTag) = obj.curTagVal;
                    save(cellData.savedFileName, 'cellData');
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
            
            if colInd > 1
                obj.updateFilter();
            end
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
            
            if colInd > 1
                obj.updateFilter();
            end
        end
        
        function updateFilter(obj)
            D = get(obj.handles.epochFilterTable,'Data');
            N = size(D,1);
            if isempty(obj.filter) || isempty(obj.filter.fieldnames)
                previousL = 0;
            else
                previousL = length(obj.filter.fieldnames);
            end
            rowsComplete = true;
            for i=1:N
                if ~isempty(D{i,1}) %change stuff and add stuff
                    obj.filter.fieldnames{i} = D{i,1};
                    obj.filter.operators{i} = D{i,2};
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
                        obj.filter.values{i} = value;
                    else
                        obj.filter.values{i} = value_str;
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
                    if isempty(obj.filter.fieldnames{i}) ...
                            || isempty(obj.filter.operators{i}) ...
                            || isempty(obj.filter.values{i})
                        rowsComplete = false;
                    end
                elseif i == previousL %remove last condition
                    obj.filter.fieldnames = obj.filter.fieldnames(1:i-1);
                    obj.filter.operators = obj.filter.operators(1:i-1);
                    obj.filter.values = obj.filter.values(1:i-1);
                    
                    pattern_str = get(obj.handles.epochFilterPatternEdit,'String');
                    pattern_str = regexprep(pattern_str, ['@' num2str(i)], '?');
                    set(obj.handles.epochFilterPatternEdit,'String',pattern_str);
                end
            end
            
            obj.filter.pattern = get(obj.handles.epochFilterPatternEdit,'String');
            if rowsComplete
                %obj.applyFilter();
            end
            if isempty(obj.filter.fieldnames)
                %reset to null filter
                obj.filter = SearchQuery();
                %obj.applyFilter(true);
            end
        end
        
        function resizeWindow(obj)
            %uitree
            if isfield(obj.handles, 'L_cellTypesPanel')
                pos = get(obj.handles.L_cellTypesPanel, 'Position');
                boxW = pos(3);
                boxH = pos(4);
                set(obj.guiTree, 'Position', [10 100 boxW - 15 boxH - 130]);
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
        end
        
    end
    
end