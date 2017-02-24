classdef CellComparisonBrowser < handle

properties
    fig
    dtab
    cellSets = {};
    currentSelection = [];
    cellNames
    handles = struct();
    
    colors = [[.1, .3, .7];
              [.68, .1, .2]];
end

methods
    
    function obj = CellComparisonBrowser(dtab, cellSets)
       obj.dtab = dtab;
       obj.currentSelection = zeros(size(dtab,1), 1);
       obj.cellNames = dtab.Properties.RowNames;
       obj.cellSets = cellSets;
      
       obj.initializeGui();
       
       obj.plotCellResponses();
       obj.updateSelectedCells();
       
    end
        
    
    
    function initializeGui(obj)
        
        obj.fig = figure( ...
            'Name',         'CellComparisonBrowser', ...
            'NumberTitle',  'off', ...
            'ToolBar',      'none',...
            'Menubar',      'none');
        
        obj.handles.mainPanel = uiextras.VBoxFlex('Parent', obj.fig);
        
        obj.handles.dataPlot = axes('Parent', obj.handles.mainPanel);
        obj.handles.dataPlotHandles = zeros(size(obj.dtab, 1), 1);
        
        obj.handles.cellLists = uiextras.HBox('Parent', obj.handles.mainPanel);
        obj.handles.cellListAll_panel = uiextras.BoxPanel('Parent', obj.handles.cellLists, ...
                'Title', 'All cells      .', ...
                'FontSize', 12, ...
                'Padding', 5);
        obj.handles.cellListAll = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellListAll_panel, ...
                'FontSize', 12, ...
                'Max', 2, ...
                'String', {'',''},... 
                'Callback', @obj.listBoxCallback);
            
        obj.handles.cellListSelected = uicontrol('Style','listbox',...
                'Parent', obj.handles.cellLists, ...
                'FontSize', 12, ...
                'Max', 2, ...
                'String', {'',''},... 
                'Callback', @obj.listBoxCallback);
        
        obj.handles.buttonRow = uiextras.HButtonBox('Parent', obj.handles.mainPanel, ...
                'ButtonSize', [100, 50]);
        
        obj.handles.button_analyzeSingleCell = uicontrol('Style', 'pushbutton', ...
                'Parent', obj.handles.buttonRow, ...
                'FontSize', 12, ...
                'String', 'Analyze cell', ...
                'Callback',@(uiobj,evt)obj.analyzeSingleCell());
            
        obj.handles.button_analyzeSingleCell = uicontrol('Style', 'pushbutton', ...
                'Parent', obj.handles.buttonRow, ...
                'FontSize', 12, ...
                'String', 'Clear selection', ...
                'Callback',@(uiobj,evt)obj.clearSelection());            
        
    end
    
    function plotCellResponses(obj)
        global CELL_DATA_FOLDER
        
        for ci = 1:size(obj.dtab,1)
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
            obj.handles.dataPlotHandles(ci) = plot(obj.handles.dataPlot, xvals, spCount, 'Color', col, ...
                    'LineWidth', 1, ...
                    'ButtonDownFcn', {@obj.cellPlotSelect, ci});
            hold(obj.handles.dataPlot, 'on')
            
        end
        hold(obj.handles.dataPlot, 'off');
        xlim(obj.handles.dataPlot, [0,2.5])
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
            hand = obj.handles.dataPlotHandles(ci);
            if hand > 0
                set(hand, 'LineWidth', wid);
            end
        end
        
        selectedCells = obj.currentSelection > 0;
        lastSelectedCell = obj.currentSelection == 2;
        
        if any(lastSelectedCell)
            val = find(find(selectedCells) == find(lastSelectedCell));
        else
            val = [];
        end
        
        obj.handles.cellListSelected.String = obj.cellNames(selectedCells);
        obj.handles.cellListSelected.Value = val;
    end
    
    function clearSelection(obj)
        obj.currentSelection = zeros(size(obj.currentSelection));
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
    
    function listBoxCallback(obj, hListbox, eventData)
       lastValue = getappdata(hListbox, 'lastValue');
       value = get(hListbox, 'Value');
       if ~isequal(value, lastValue)
          value2 = setdiff(value, lastValue);
          if isempty(value2)
             setappdata(hListbox, 'lastValue', value);
          else
             value = value2(1);  % see quirk below
             setappdata(hListbox, 'lastValue', value);
             set(hListbox, 'Value', value);
          end
       end
       
    end    


end

end