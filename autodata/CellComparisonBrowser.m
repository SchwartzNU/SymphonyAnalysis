classdef CellComparisonBrowser < handle
    
properties
    mainFigure
    dtab
    dtabColumns
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

function obj = CellComparisonBrowser(dtab, dtabColumns, cellSets, cellSetNames)
    obj.dtab = dtab;
    obj.dtabColumns = dtabColumns;
    obj.currentSelection = zeros(size(dtab,1), 1);
    obj.cellNames = dtab.Properties.RowNames;
    obj.cellSets = cellSets;
    obj.cellSetNames = cellSetNames;
    obj.numCells = length(obj.cellNames);

    obj.initializeGui();


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

    obj.handles.dataPlotObjects = {};

    obj.handles.cellLists = uiextras.VBox('Parent', obj.handles.mainPanel);

    obj.handles.cellLists_top = uiextras.HBox('Parent', obj.handles.cellLists);


    % % LEFT TOP CELL LISTS
    obj.handles.cellListAll_panel = uiextras.BoxPanel('Parent', obj.handles.cellLists_top, ...
        'Title', 'All cells       ', ...
        'Padding', 5);
    obj.handles.cellListAll = uicontrol('Style','listbox',...
        'Parent', obj.handles.cellListAll_panel, ...
        'FontSize', 12,...
        'Max', 2, ...
        'String', obj.renderCellNames(ones(obj.numCells,1)));

    obj.handles.cellListSelected_panel = uiextras.BoxPanel('Parent', obj.handles.cellLists_top, ...
        'Title', 'Selected Cells       ', ...
        'Padding', 5);
    obj.handles.cellListSelected = uicontrol('Style','listbox',...
        'Parent', obj.handles.cellListSelected_panel, ...
        'FontSize', 12,...       
        'Max', 2, ...
        'String', {'Selected',''});


    % % LEFT BOTTOM CELL SETS
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
            'FontSize', 12,...
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
        'FontSize', 12,...
        'String', CellComparisonPlotter.plotModeOptions);
    obj.handles.button_addNewPlot = uicontrol('Style', 'pushbutton', ...
        'Parent', plotControlBox, ...
        'String', 'New Plotter', ...
        'Callback', @(uiobj,evt)obj.addNewDataPlotButtonCallback());    


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


    set(obj.handles.mainPanel, 'Sizes', [-2, -.5, -1]);

end


function addNewDataPlotButtonCallback(obj, ~, ~)
    plotModeIndex = get(obj.handles.listOfPlotters, 'Value');
    plotMode = CellComparisonPlotter.plotModeOptions{plotModeIndex};
    obj.addNewDataPlot(plotMode);
end

function addNewDataPlot(obj, plotMode)
    dataPlotFigureId = 1 + length(obj.handles.dataPlotObjects);
    plotterClassName = ['CellComparisonPlotter_' plotMode];
    newPlot = feval(plotterClassName, obj);
    obj.handles.dataPlotObjects{dataPlotFigureId} = newPlot;
end



function updateSelectedCells(obj, lastSelected)
    % update selection sets
    if nargin > 1
        if obj.currentSelection(lastSelected) > 0 % deselect
            obj.currentSelection(lastSelected) = 0;
        else
            obj.currentSelection(obj.currentSelection > 0) = 1;
            obj.currentSelection(lastSelected) = 2;
        end
    end
    
    selectedCells = obj.currentSelection > 0;
    lastSelectedCell = obj.currentSelection == 2;

    if any(lastSelectedCell)
        val = find(find(selectedCells) == find(lastSelectedCell));
    else
        val = [];
    end

    % update gui list
    obj.handles.cellListSelected.String = obj.renderCellNames(selectedCells);
    obj.handles.cellListSelected.Value = val;
    
    % call each plotter to update
    for figi = 1:length(obj.handles.dataPlotObjects)
    	dataPlot = obj.handles.dataPlotObjects{figi};
        dataPlot.updateSelection();
    end    
end

function updateCellSets(obj)
    % update gui lists
    for si = 1:length(obj.cellSets)
        listHandle = obj.handles.cellSetLists(si);
        cellNamesInSet = obj.renderCellNames(obj.cellSets{si});
        set(listHandle, 'String', cellNamesInSet);
        set(obj.handles.cellSetLists_panels(si), 'Title', sprintf('Set %g: %s      ', si, obj.cellSetNames{si}));
    end
    
    % call each plotter to update
    for figi = 1:length(obj.handles.dataPlotObjects)
        dataPlot = obj.handles.dataPlotObjects{figi};
        dataPlot.updateCellSets();
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
    if ~any(obj.currentSelection)
        return
    end
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

function setsByCell = getSetsByCell(obj)
    % use the max function to get the column index with the highest number
    % add a column of 0.1 to be the fake max where otherwise only zeros (not a member of any set)
    % then remove that column's effects
    [~,setsByCell] = max(horzcat(0.1*ones(obj.numCells,1), cell2mat(obj.cellSets)), [], 2);
    setsByCell = setsByCell - 1;
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