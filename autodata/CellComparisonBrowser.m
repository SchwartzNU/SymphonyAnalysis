classdef CellComparisonBrowser < handle

properties
    mainFigure
    dtab
    cellSets = {};
    cellSetNames = {};
    currentSelection = [];
    cellNames
    numCells
    handles = struct();
    
    colors = [[.1, .3, .7];
              [.68, .1, .2]];
end

methods
    
    function obj = CellComparisonBrowser(dtab, cellSets, cellSetNames)
       obj.dtab = dtab;
       obj.currentSelection = zeros(size(dtab,1), 1);
       obj.cellNames = dtab.Properties.RowNames;
       obj.cellSets = cellSets;
       obj.cellSetNames = cellSetNames;
       obj.numCells = length(obj.cellNames);
      
       obj.initializeGui();
       
%        plotConfiguration = struct();
%        plotConfiguration.name = 'new plot name';
%        obj.addNewDataPlot(plotConfiguration);
       
       obj.updateSelectedCells();
       obj.updateCellSets();
    end
        
    
    
    function initializeGui(obj)
        
        obj.mainFigure = figure( ...
            'Name',         'CellComparisonBrowser', ...
            'NumberTitle',  'off', ...
            'ToolBar',      'none',...
            'Menubar',      'none');
        
        obj.handles.mainPanel = uiextras.HBox('Parent', obj.mainFigure);
        
        obj.handles.dataPlotFigureHandles = [];
        obj.handles.dataPlotAxisHandles = [];
        
        obj.handles.cellLists = uiextras.VBox('Parent', obj.handles.mainPanel);
        
        obj.handles.cellLists_top = uiextras.HBox('Parent', obj.handles.cellLists);
        
        
        % % TOP CELL LISTS
        obj.handles.cellListAll_panel = uiextras.BoxPanel('Parent', obj.handles.cellLists_top, ...
                'Title', 'All cells       ', ...
                'Padding', 5);
        obj.handles.cellListAll = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellListAll_panel, ...
                'Max', 2, ...
                'String', obj.renderCellNames(ones(obj.numCells,1)));
            
        obj.handles.cellListSelected_panel = uiextras.BoxPanel('Parent', obj.handles.cellLists_top, ...
                'Title', 'Selected Cells       ', ...
                'Padding', 5);
        obj.handles.cellListSelected = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellListSelected_panel, ...
                'Max', 2, ...
                'String', {'Selected',''});
        
            
        % % CELL SETS
        obj.handles.cellSetsBox = uiextras.HBox('Parent', obj.handles.cellLists);
        obj.handles.cellSetLists = [];
        obj.handles.cellSetLists_panels = [];
        for si = 1:length(obj.cellSets)
            setBox = uiextras.VBox('Parent', obj.handles.cellSetsBox);
            obj.handles.cellSetLists_panels(si) = uiextras.BoxPanel('Parent', setBox, ...
                    'Title', [sprintf('Set %g', si) '       '], ...
                    'Padding', 5);            
            obj.handles.cellSetLists(si) = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellSetLists_panels(si), ...
                'Max', 2, ...
                'String', {sprintf('set %g', si),''});
            setButtonRow = uiextras.HButtonBox('Parent', setBox, ...
                'ButtonSize', [100, 30]);
            obj.handles.cellSetLists_removeButton = uicontrol('Style', 'pushbutton', ...
                'Parent', setButtonRow, ...
                'String', 'Remove', ...
                'Callback', {@obj.removeCellFromSet, si});
            obj.handles.cellSetLists_addSelectedButton = uicontrol('Style', 'pushbutton', ...
                'Parent', setButtonRow, ...
                'String', 'Add selected', ...
                'Callback', {@obj.addSelectedCellToSet, si});
            obj.handles.cellSetLists_addToSelectionButton = uicontrol('Style', 'pushbutton', ...
                'Parent', setButtonRow, ...
                'String', 'Select', ...
                'Callback', {@obj.addCellToSelection, si});                   
        end
        
        % % PLOT CONTROLS
        
        plotControlBox = uiextras.VBox('Parent', obj.handles.mainPanel);
        obj.handles.listOfPlotters = uicontrol('Style','listbox',...
                'Parent', plotControlBox, ...
                'String', {'Plotters',''});
        
            
        % % MAIN BUTTONS (mostly accessory)
        mainButtonRow = uiextras.HButtonBox('Parent', obj.handles.mainPanel, ...
                'ButtonSize', [100, 50]);
        
        obj.handles.button_analyzeSingleCell = uicontrol('Style', 'pushbutton', ...
                'Parent', mainButtonRow, ...
                'String', 'Analyze cell', ...
                'Callback', @(uiobj,evt)obj.analyzeSingleCell());
            
        obj.handles.button_clearSelection = uicontrol('Style', 'pushbutton', ...
                'Parent', mainButtonRow, ...
                'String', 'Clear selection', ...
                'Callback', @(uiobj,evt)obj.clearSelection());
        
    end
    
    function plotCellResponses(obj, figId)
        global CELL_DATA_FOLDER
        fig = obj.handles.dataPlotFigureHandles(figId);
        ax = axes('Parent', fig);
        obj.handles.dataPlotAxisHandles(figId) = ax;
        obj.handles.dataPlotLineHandles{figId} = zeros(length(obj.cellNames),1);
        
        for ci = 1:obj.numCells
        %  set color of lines by group
            col = [];
            for si = 1:length(obj.cellSets)
                cellSet = obj.cellSets{si};
                if cellSet(ci)
                    col = obj.colors(si,:);
                end
            end
            if isempty(col)
                continue
            end

            bestSize = obj.dtab{ci, 'SMS_offSpikes_prefSize'};
            if isnan(bestSize)
                continue
            end

            dataSet = obj.dtab{ci, 'SMS_sp_dataset'}{1};
            load([CELL_DATA_FOLDER obj.cellNames{ci}])
            if ~isKey(cellData.savedDataSets, dataSet)
                continue
            end
            epochIds = cellData.savedDataSets(dataSet);
            matchingEpochs = [];
            for ei = 1:length(epochIds)
                eid = epochIds(ei);
                epoch = cellData.epochs(eid);
                if abs(epoch.get('curSpotSize') - bestSize) < 1
                    matchingEpochs(end+1) = eid;
                    
                end
            end

            if isempty(matchingEpochs)
%                 disp(['umm ' obj.cellNames{ci}])
%                 ci
                continue
            end

        %     [dataMean, xvals, dataStd, units] = cellData.getMeanData(matchingEpochs, streamName);
            [spCount, xvals] = cellData.getPSTH(matchingEpochs, 40); % bin length in ms
            lineHandle = plot(ax, xvals, spCount, 'Color', col, ...
                    'LineWidth', 1, ...
                    'ButtonDownFcn', {@obj.cellPlotSelect, ci});
            hold(ax, 'on')
            obj.handles.dataPlotLineHandles{figId}(ci) = lineHandle;
            
        end
        hold(ax, 'off');
        xlim(ax, [0,2.5])
    end
    
    
    function addNewDataPlot(obj, plotConfiguration)
        dataPlotFigureId = 1 + length(obj.handles.dataPlotFigureHandles);
        fig = figure( ...
                'Name',         plotConfiguration.name, ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none');
        obj.handles.dataPlotFigureHandles(dataPlotFigureId) = fig;
        
        obj.plotCellResponses(dataPlotFigureId);
    end
    
    function cellPlotSelect(obj, ~, ~, ci)
        fprintf('%s: %s %g\n', obj.dtab.cellType{ci}, obj.dtab.Properties.RowNames{ci}, ci);
        obj.updateSelectedCells(ci)
    end
    
    function updateSelectedCells(obj, lastSelected)
        if nargin > 1
            if obj.currentSelection(lastSelected) > 0 % deselect
                obj.currentSelection(lastSelected) = 0;
            else
                obj.currentSelection(obj.currentSelection > 0) = 1;
                obj.currentSelection(lastSelected) = 2;
            end
        end
        
        % set width of lines by selection state
        for ci = 1:length(obj.cellNames)
            state = obj.currentSelection(ci);
            switch state
                case 0
                    wid = 1;
                case 1
                    wid = 3;
                case 2
                    wid = 4;
            end
            for fi = 1:length(obj.handles.dataPlotAxisHandles)
                lineHandles = obj.handles.dataPlotLineHandles{fi};
                if lineHandles(ci) > 0
                    set(lineHandles(ci), 'LineWidth', wid);
                end
            end
        end
        
        selectedCells = obj.currentSelection > 0;
        lastSelectedCell = obj.currentSelection == 2;
        
        if any(lastSelectedCell)
            val = find(find(selectedCells) == find(lastSelectedCell));
        else
            val = [];
        end
        
        obj.handles.cellListSelected.String = obj.renderCellNames(selectedCells);
        obj.handles.cellListSelected.Value = val;
    end
    
    function updateCellSets(obj)
        for si = 1:length(obj.cellSets)
            listHandle = obj.handles.cellSetLists(si);
            cellNamesInSet = obj.renderCellNames(obj.cellSets{si});
            set(listHandle, 'String', cellNamesInSet);
            set(obj.handles.cellSetLists_panels(si), 'Title', sprintf('Set %g: %s      ', si, obj.cellSetNames{si}));
        end
        for fi = 1:length(obj.handles.dataPlotAxisHandles)
            lineHandles = obj.handles.dataPlotLineHandles{fi};
            for ci = 1:length(obj.cellNames)
                if lineHandles(ci) > 0
                    
                    % figure out which set this cell is in (ideally one)
                    thisCellsSet = [];
                    for si = 1:length(obj.cellSets)
                        if obj.cellSets{si}(ci)
                            thisCellsSet = si;
                        end
                        if ~isempty(thisCellsSet)
                            set(lineHandles(ci), 'Color', obj.colors(thisCellsSet,:));
                        end
                    end
                end
            end
        end
    end
    
    function clearSelection(obj)
        obj.currentSelection = zeros(size(obj.currentSelection));
        obj.updateSelectedCells();
    end
    
    function removeCellFromSet(obj, ~, ~, cellSetId)
        setListHandle = obj.handles.cellSetLists(cellSetId);
        indexInList = get(setListHandle, 'Value');
        selectedIndices = find(obj.cellSets{cellSetId});
        ci = selectedIndices(indexInList);
        set(setListHandle, 'Value',1)

        obj.cellSets{cellSetId}(ci) = 0;
        obj.updateCellSets();
    end
    
    function addSelectedCellToSet(obj, ~, ~, cellSetId)
        obj.cellSets{cellSetId}(obj.currentSelection) = 1;
        obj.updateCellSets();
    end
    
    function addCellToSelection(obj, ~, ~, cellSetId)
        setListHandle = obj.handles.cellSetLists(cellSetId);
        indexInList = get(setListHandle, 'Value');
        selectedIndices = find(obj.cellSets{cellSetId});
        ci = selectedIndices(indexInList);
        obj.currentSelection(ci) = 1;
        
        obj.updateSelectedCells();
    end
    
    function analyzeSingleCell(obj, ~)
        cellName = obj.cellNames{obj.currentSelection == 2};
        if isempty(cellName)
            return
        end
        cellType = '';

        labData = LabData();
        labData.addCell(cellName, cellType);
        labData.analyzeCells(cellName);
        tempTree = labData.collectCells(cellName);
        TreeBrowserGUI(tempTree); 
        
    end
    
    function s = renderCellNames(obj, cellSet)
        s = cell(sum(cellSet), 1);
        si = 1;
        for ci = 1:obj.numCells
            if cellSet(ci)
                s{si} = sprintf('%s %s', obj.cellNames{ci}, obj.dtab.cellType{ci});
                si = si + 1;
            end
        end
    end
            
    
%     function listBoxCallback(~, hListbox, ~)
%        lastValue = getappdata(hListbox, 'lastValue');
%        value = get(hListbox, 'Value');
%        if ~isequal(value, lastValue)
%           value2 = setdiff(value, lastValue);
%           if isempty(value2)
%              setappdata(hListbox, 'lastValue', value);
%           else
%              value = value2(1);  % see quirk below
%              setappdata(hListbox, 'lastValue', value);
%              set(hListbox, 'Value', value);
%           end
%        end
%        
%     end    


end

end