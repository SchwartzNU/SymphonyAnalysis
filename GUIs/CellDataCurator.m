classdef CellDataCurator < handle
    %GUI for curating epoch data from single cells
    
    properties
        cellData
    end
    
    properties (Hidden)
        fig
        handles
        filter = SearchQuery();
        selectedEpochInd = 1;
        curViewParams = {};
        curViewLocations = {};
        dataSet %vector of epoch indices
        allKeys     
        epochsInDataSets = [];
        quickParamsFilterList = {};
    end
    
    properties (Hidden, Constant)
       operators = {' ','==','>','<','>=','<=','~='}; 
    end
    
    methods
        function obj = CellDataCurator(cellData)
            if nargin < 1
                return
            end
            
            obj.cellData = cellData;
            obj.dataSet = 1:cellData.get('Nepochs');
            
            obj.buildUIComponents();
            obj.updateParamsList();            
            obj.initializeFilterTable();
            obj.initializeEpochsInDataSetsList();
            obj.updateDataPlot();
            obj.updateDiaryPlot();
            obj.initializeFilterResultsTable();
            obj.initializeCurEpochTable();            
            obj.updateDataSetMenu();
            if isempty(obj.cellData.savedFileName)
                obj.chooseSaveLocation();
            end
            
            %             self.isBusy = true;
            %             self.initAnalysisTools;
            %             self.initTreeBrowser;
            %             self.isBusy = false;
        end
        
        function buildUIComponents(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['CellDataCurator: ' obj.cellData.savedFileName], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ...
                'Position', [0 0.85*bounds(1,4), 0.8*bounds(1,3), 0.6*bounds(1,4)], ...
                'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt), ...
                'ResizeFcn', @(uiobj,evt)obj.resizeWindow);
            
            L_main = uiextras.VBox('Parent', obj.fig);
            L_panels = uiextras.HBoxFlex('Parent', L_main, ...
                'Spacing', 10);            
            set(L_main, 'Sizes', -1);
            
            L_dataPanels = uiextras.VBoxFlex('Parent', L_panels);
            L_filterPanels = uiextras.VBoxFlex('Parent', L_panels, ...
                'Spacing', 10);
            set(L_panels, 'Sizes', [-1, -1], 'Padding', 5);
            
            L_diaryPlot = uiextras.VBox('Parent', L_dataPanels);
            obj.handles.diaryPlotAxes = axes('Parent', L_diaryPlot);
            L_diaryMenu = uiextras.HBox('Parent', L_diaryPlot);
            diaryYMenuText = uicontrol('Parent', L_diaryMenu, ...
                'Style', 'text', ...
                'String', 'Y-axis', ...
                'FontSize', 11);
            obj.handles.diaryYMenu = uicontrol('Parent', L_diaryMenu, ...
                'Style', 'popupmenu', ...
                'String', obj.allKeys, ...
                'Units', 'normalized', ...
                'Callback', @(uiobj, evt)obj.updateDiaryPlot);
            diaryXMenuText = uicontrol('Parent', L_diaryMenu, ...
                'Style', 'text', ...
                'String', 'X-axis', ...
                'FontSize', 11);
            obj.handles.diaryXMenu = uicontrol('Parent', L_diaryMenu, ...
                'Style', 'popupmenu', ...
                'String', {'time','epochNum'}, ...
                'Units', 'normalized', ...
                'Callback', @(uiobj, evt)obj.updateDiaryPlot);            
            set(L_diaryMenu, 'Sizes', [80, 220, 80, 200], 'Spacing', 20);
            set(L_diaryPlot, 'Sizes', [-1, 20], 'Padding', 5);
            
            L_dataPlot = uiextras.VBox('Parent', L_dataPanels);
           
            obj.handles.dataPlotAxes = axes('Parent', L_dataPlot);
            L_dataPlotControls = uiextras.HBox('Parent', L_dataPlot);
            set(L_dataPlot, 'Sizes', [-1, 35], 'Padding', 5);
            
            channelMenuText = uicontrol('Parent', L_dataPlotControls, ...
                'Style', 'text', ...
                'String', 'Data channel', ...
                'FontSize', 11);
            obj.handles.channelMenu = uicontrol('Parent', L_dataPlotControls, ...
                'Style', 'popupmenu', ...
                'String', {'Amplifier_Ch1', 'Amplifier_Ch2'}, ...
                'Callback', @(uiobj, evt)obj.updateDataPlot);
            
            L_scrollButtons = uiextras.HButtonBox('Parent', L_dataPlotControls);
            set(L_dataPlotControls, 'Sizes', [100, 150, 100], 'Spacing', 20);
            
            obj.handles.dataBackwardButton = uicontrol('Parent', L_scrollButtons, ...
                'Style', 'pushbutton', ...
                'String', '<', ...
                'Callback', @(uiobj, evt)obj.decrementEpochInd);
            obj.handles.dataForwardButton = uicontrol('Parent', L_scrollButtons, ...
                'Style', 'pushbutton', ...
                'String', '>', ...
                'Callback', @(uiobj, evt)obj.incrementEpochInd);
            
            set(L_scrollButtons, ...
                'ButtonSize', [30 20]);
            L_controls = uiextras.HBox('Parent', L_dataPanels, 'Spacing', 20);

            obj.handles.saveDataSetButton = uicontrol('Parent', L_controls, ...
                'Style', 'pushbutton', ...
                'String', 'Save data set', ...
                'Callback', @(uiobj, evt)obj.saveDataSetFunc);
            obj.handles.dataSetsMenu = uicontrol('Parent', L_controls, ...
                'Style', 'popupmenu', ...
                'String', 'Data sets ...', ...
                'Callback', @(uiobj,evt)obj.loadDataSet); 
            obj.handles.renameDataSetButton = uicontrol('Parent', L_controls, ...
                'Style', 'pushbutton', ...
                'String', 'Rename data set', ...
                'Callback', @(uiobj, evt)obj.renameDataSet);
            obj.handles.deleteDataSetButton = uicontrol('Parent', L_controls, ...
                'Style', 'pushbutton', ...
                'String', 'Delete data set', ...
                'Callback', @(uiobj, evt)obj.deleteDataSet);
            uicontrol('Parent', L_controls, ...
                'Style', 'pushbutton', ...
                'String', 'Reset view', ...
                'Callback', @(uiobj, evt)obj.resetView);
            
            set(L_dataPanels, 'Sizes', [-1, -1, 40], 'Padding', 5);
            set(L_controls, 'Sizes', [100, 200, 100, 100, 100]);
            
            L_quickFilterBox = uiextras.HBox('Parent',L_filterPanels);
            L_filterDisplayNames = uiextras.VBox('Parent',L_quickFilterBox);
            obj.handles.filterDisplayNamesMenu = uicontrol('Parent',L_filterDisplayNames, ...
                'Style', 'popupmenu', ...
                'String', {'default'}, ...
                'Callback', @(uiobj, evt) obj.makeDisplayNameFilter);
            
            L_filterVoltages = uiextras.VBox('Parent',L_quickFilterBox);
            obj.handles.filterVoltagesMenu = uicontrol('Parent',L_filterVoltages, ...
                'Style', 'popupmenu', ...
                'String', {'default'}, ...
                'Callback', @(uiobj, evt) obj.makeVoltagesFilter);
            
            L_filterParams = uiextras.VBox('Parent',L_quickFilterBox);
            obj.handles.filterParamsMenu = uicontrol('Parent',L_filterParams, ...
                'Style', 'popupmenu', ...
                'String', {'default'}, ...
                'Callback', @(uiobj, evt) obj.makeParamsFilter);
            
            
            L_filterBox = uiextras.VBox('Parent',L_filterPanels);
            filterText = uicontrol('Parent', L_filterBox, ...
                'Style', 'text', ...
                'String', 'Filter Construction', ...
                'FontSize', 12);            
            obj.handles.filterTable = uitable('Parent', L_filterBox, ...
                'Units',    'pixels', ...
                'FontSize', 11, ...
                'ColumnName', {'Param', 'Operator', 'Value'}, ...
                'ColumnEditable', logical([1 1 1]), ...
                'Data', cell(12,3), ...
                'CellEditCallback', @(uiobj, evt)obj.filterTableEdit(evt), ...
                'TooltipString', 'table for filter contruction');
            L_filterPattern = uiextras.HBox('Parent',L_filterBox);
            filterPatternText = uicontrol('Parent', L_filterPattern, ...
                'Style', 'text', ...
                'String', 'Filter pattern string', ...
                'FontSize', 11);
            obj.handles.filterPatternEdit = uicontrol('Parent', L_filterPattern, ...
                'Style', 'Edit', ...
                'FontSize', 11, ...
                'CallBack', @(uiobj, evt)obj.updateFilter);
            set(L_filterPattern, 'Sizes', [100, -1], 'Spacing', 20);
            L_filterControls = uiextras.HButtonBox('Parent', L_filterBox, ...
                'ButtonSize', [100 30], ...
                'Spacing', 20);
            obj.handles.saveFilterButton = uicontrol('Parent', L_filterControls, ...
                'Style', 'pushbutton', ...
                'String', 'Save filter', ...
                'Callback', @(uiobj,evt)obj.saveFilter);
            obj.handles.loadFilterButton = uicontrol('Parent', L_filterControls, ...
                'Style', 'pushbutton', ...
                'String', 'Load filter', ...
                'Callback', @(uiobj,evt)obj.loadFilter);
            set(L_filterBox, 'Sizes', [25, -1, 25, 40]);
            
            L_filterResultsBox = uiextras.VBox('Parent',L_filterPanels);
            obj.handles.filterResultsText = uicontrol('Parent', L_filterResultsBox, ...
                'Style', 'text', ...
                'String', 'Parameters With Multiple Values', ...
                'FontSize', 12);           
            obj.handles.filterResultsTable = uitable('Parent', L_filterResultsBox, ...
                'Units',    'pixels', ...
                'FontSize', 11, ...
                'ColumnEditable', logical([0 0]), ...
                'ColumnName', [], ...
                'RowName', [], ...
                'ColumnFormat', {'char', 'char'}, ...
                'Data', cell(12,2), ...
                'TooltipString', 'table for filter results');   
            L_paramControl = uiextras.Grid('Parent', L_filterResultsBox, 'Spacing', 10);
            paramControl_text = uicontrol('Parent', L_paramControl, ...
                'Style', 'text', ...
                'String', 'Add/delete parameters', ...
                'FontSize', 11);
            uiextras.Empty('Parent', L_paramControl);
            paramName_text = uicontrol('Parent', L_paramControl, ...
                'Style', 'text', ...
                'String', 'Name:', ...
                'FontSize', 11);
            obj.handles.paramNameEdit = uicontrol('Parent', L_paramControl, ...
                'Style', 'edit', ...
                'String', '', ...
                'FontSize', 11);
            paramVal_text = uicontrol('Parent', L_paramControl, ...
                'Style', 'text', ...
                'String', 'Value:', ...
                'FontSize', 11);
            obj.handles.paramValEdit = uicontrol('Parent', L_paramControl, ...
                'Style', 'edit', ...
                'String', '', ...
                'FontSize', 11);
            obj.handles.addParamToEpochButton = uicontrol('Parent', L_paramControl, ...
                'Style', 'pushbutton', ...
                'String', 'Add to current epoch', ...
                'Callback', @(uiobj,evt)obj.addParamToEpoch);
            obj.handles.addParamToDataSetButton = uicontrol('Parent', L_paramControl, ...
                'Style', 'pushbutton', ...
                'String', 'Add to data set', ...
                'Callback', @(uiobj,evt)obj.addParamToDataSet);
            obj.handles.deleteParamFromEpochButton = uicontrol('Parent', L_paramControl, ...
                'Style', 'pushbutton', ...
                'String', 'Delete from current epoch', ...
                'Callback', @(uiobj,evt)obj.deleteParamFromEpoch);
            obj.handles.deleteParamFromDataSetButton = uicontrol('Parent', L_paramControl, ...
                'Style', 'pushbutton', ...
                'String', 'Delete from data set', ...
                'Callback', @(uiobj,evt)obj.deleteParamFromDataSet);
            set(L_paramControl, 'ColumnSizes', [100 -1 -1 150 150], ...
                'RowSizes', [40 40], 'Padding', 0);
            set(L_filterResultsBox, 'Sizes', [25, -1, 90], 'Padding', 5);
            
            L_currentEpochParamsBox = uiextras.VBox('Parent',L_filterPanels);
            currentEpochParamsText = uicontrol('Parent', L_currentEpochParamsBox, ...
                'Style', 'text', ...
                'String', 'Current Epoch Parameters', ...
                'FontSize', 12);
            obj.handles.curEpochTable = uitable('Parent', L_currentEpochParamsBox, ...
                'Units',    'pixels', ...
                'FontSize', 11, ...
                'ColumnEditable', logical([1, 0, 1, 0]), ...
                'ColumnName', {'Param', 'Value', 'Param', 'Value'}, ...
                'RowName', [], ...
                'Data', cell(6,4), ...
                'CellEditCallback', @(uiobj, evt)obj.curEpochTableEdit(evt), ...
                'TooltipString', 'table for current epoch parameters');
            L_viewControls = uiextras.HButtonBox('Parent', L_currentEpochParamsBox, ...
                'ButtonSize', [100 30], ...
                'Spacing', 20);
            obj.handles.saveViewButton = uicontrol('Parent', L_viewControls, ...
                'Style', 'pushbutton', ...
                'String', 'Save view', ...
                'Callback', @(uiboj, evt)obj.saveViewFunc);
            obj.handles.loadViewButton = uicontrol('Parent', L_viewControls, ...
                'Style', 'pushbutton', ...
                'String', 'Load view', ...
                'Callback', @(uiboj, evt)obj.loadViewFunc);
            set(L_currentEpochParamsBox, 'Sizes', [25, -1 50], 'Padding', 5);
            
            set(L_filterPanels, 'Sizes', [20, -1, -1, -1], 'Padding', 5);
            
        end
        
        function updateDataPlot(obj)
            cla(obj.handles.dataPlotAxes);
            if isempty(obj.dataSet)
                return;
            end
            channels = get(obj.handles.channelMenu,'String');
            selectedChannelStr = channels{get(obj.handles.channelMenu,'Value')};
            epochNum = obj.dataSet(obj.selectedEpochInd);
            obj.cellData.epochs(epochNum).plotData(selectedChannelStr, obj.handles.dataPlotAxes);
            title(obj.handles.dataPlotAxes, sprintf('Epoch number: %g', epochNum));
        end
        
        function updateParamsList(obj)
            obj.allKeys = obj.cellData.getEpochKeysetUnion(obj.dataSet);
            if isempty(obj.allKeys)
                warning('No epochs match these settings');
            
            else
                set(obj.handles.diaryYMenu,'String',obj.allKeys);
                %set to displayName as default
                displayNameInd = find(strcmp(obj.allKeys, 'displayName'));
                set(obj.handles.diaryYMenu, 'Value', displayNameInd);
                %update popupmenu for filter table
                props = [' ', obj.allKeys];
                columnFormat = {props, obj.operators, 'char'};
                set(obj.handles.filterTable,'ColumnFormat',columnFormat)
            end
        end
        
        function updateDiaryPlot(obj)
            cla(obj.handles.diaryPlotAxes);
            if isempty(obj.dataSet)
                return;
            end
%             epochTimes = obj.cellData.getEpochVals('epochStartTime', obj.dataSet);
            epochNums = obj.cellData.getEpochVals('epochNum', obj.dataSet);
            epochTimes = obj.cellData.getEpochVals('epochStartTime', obj.dataSet);
            a = get(obj.handles.diaryXMenu,'Value');
            s = get(obj.handles.diaryXMenu,'String');
            xmode = s(a);
            if strcmp(xmode, 'epochNum')
                xvals = epochNums;
            else
                xvals = epochTimes;
            end            
            displayParam = obj.allKeys{get(obj.handles.diaryYMenu,'Value')};
            displayVals = obj.cellData.getEpochVals(displayParam, obj.dataSet);
        
            if isnumeric(displayVals)   
                hold(obj.handles.diaryPlotAxes, 'on');
                inDataSetInd = ismember(obj.dataSet, obj.epochsInDataSets);
                obj.handles.diaryPlotLine = plot(obj.handles.diaryPlotAxes, xvals(~inDataSetInd), displayVals(~inDataSetInd), 'bo');
                obj.handles.diaryPlotLine = plot(obj.handles.diaryPlotAxes, xvals(inDataSetInd), displayVals(inDataSetInd), 'go', 'MarkerFaceColor', 'g');
                
                plot(obj.handles.diaryPlotAxes, xvals(obj.selectedEpochInd), displayVals(obj.selectedEpochInd), 'bo', 'MarkerFaceColor', 'r');
                
                set(obj.handles.diaryPlotAxes, 'YtickMode', 'auto', 'YtickLabelMode', 'auto');
                set(obj.handles.diaryPlotAxes, 'Ylim', [min(displayVals) - .1 * range(displayVals) - .1, max(displayVals) + .1 * range(displayVals) + .1]);
            else
                % remove nans
                for i = 1:length(displayVals)
                    if isnan(displayVals{i})
                        displayVals{i} = '-unset-';
                    end
                end
                
                uniqueVals = unique(displayVals);
                valInd = zeros(1,length(displayVals));
                for i=1:length(uniqueVals)
                    valInd(strcmp(displayVals, uniqueVals{i})) = i;
                end
                hold(obj.handles.diaryPlotAxes, 'on');
                inDataSetInd = ismember(obj.dataSet, obj.epochsInDataSets);

                obj.handles.diaryPlotLine = plot(obj.handles.diaryPlotAxes, xvals(~inDataSetInd), valInd(~inDataSetInd), 'bo');
                obj.handles.diaryPlotLine = plot(obj.handles.diaryPlotAxes, xvals(inDataSetInd), valInd(inDataSetInd), 'go', 'MarkerFaceColor', 'g');

                plot(obj.handles.diaryPlotAxes, xvals(obj.selectedEpochInd), valInd(obj.selectedEpochInd), 'bo', 'MarkerFaceColor', 'r');
                set(obj.handles.diaryPlotAxes, 'Ytick', unique(valInd), 'YtickLabel', uniqueVals);
                set(obj.handles.diaryPlotAxes, 'Ylim', [0 max(valInd)+1]);
                %text labels here
            end
            
            ylabel(obj.handles.diaryPlotAxes, displayParam);
            if strcmp(xmode, 'epochNum')
                xlabel('Epoch Number');
            else
                xlabel('Epoch Time (sec)');
            end  
            hold(obj.handles.diaryPlotAxes, 'off');
            
            set(obj.handles.diaryPlotAxes, 'ButtonDownFcn', @(uiobj,evt)obj.diaryPlotClick);
        end
        
        function keyHandler(obj, evt)
            switch evt.Key
                case 'leftarrow'
                    obj.decrementEpochInd();
                case 'rightarrow'
                    obj.incrementEpochInd();
                case 'escape'
                    delete(obj.fig);
                otherwise
                    disp(evt.Key);
            end
        end
        
        function initializeEpochsInDataSetsList(obj)
           k = obj.cellData.savedDataSets.keys;
           for i=1:length(k)
               obj.epochsInDataSets = [obj.epochsInDataSets obj.cellData.savedDataSets(k{i})];
           end
        end
        
        function curEpochTableEdit(obj, eventData)
            newData = eventData.EditData;
            rowInd = eventData.Indices(1);
            colInd = eventData.Indices(2);
            D = get(obj.handles.curEpochTable,'Data');
            
            if strcmp(newData,' ') %blank the param
                D{rowInd,colInd} = '';
                D{rowInd,colInd+1} = '';
            else
                D{rowInd,colInd} = newData;
            end
                
            set(obj.handles.curEpochTable,'Data',D);
            obj.updateCurEpochTable();            
        end
        
        function filterTableEdit(obj, eventData)
            newData = eventData.EditData;
            rowInd = eventData.Indices(1);
            colInd = eventData.Indices(2);
            D = get(obj.handles.filterTable,'Data');
            
            if strcmp(newData,' ') %blank the row
                D{rowInd,1} = '';
                D{rowInd,2} = '';
                D{rowInd,3} = '';
            else
                D{rowInd,colInd} = newData;
            end
            if colInd == 1 %edited parameter name
                %show unique values
                vals = obj.cellData.getEpochVals(newData);
                vals = vals(~isnan_cell(vals));
                vals = unique(vals);
                D{rowInd,3} = makeDelimitedString(vals);
            end
                
            set(obj.handles.filterTable,'Data',D);
            
            if colInd > 1 %why?
                obj.updateFilter();
            end
        end
                
        function updateFilter(obj)
            D = get(obj.handles.filterTable,'Data');
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
                        pattern_str = get(obj.handles.filterPatternEdit,'String');
                        if previousL == 0 %first condition
                            pattern_str = '@1';
                        else
                            pattern_str = [pattern_str ' && @' num2str(i)];
                        end
                        set(obj.handles.filterPatternEdit,'String',pattern_str);
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
                    
                    pattern_str = get(obj.handles.filterPatternEdit,'String');
                    pattern_str = regexprep(pattern_str, ['@' num2str(i)], '?');
                    set(obj.handles.filterPatternEdit,'String',pattern_str);
                end
            end
            
            obj.filter.pattern = get(obj.handles.filterPatternEdit,'String');
            if rowsComplete
                obj.applyFilter();
            end
            if isempty(obj.filter.fieldnames)
               %reset to null filter
               obj.filter = SearchQuery();
               obj.applyFilter(true);
            end
        end
        
        function applyFilter(obj)
            if nargin < 2
                queryString = obj.filter.makeQueryString();
            else
                queryString = 'true';
            end
            obj.dataSet = obj.cellData.filterEpochs(queryString);        
            obj.updateParamsList();
            obj.selectedEpochInd = 1;
            obj.updateDiaryPlot();
            obj.updateDataPlot();
            obj.updateFilterResultsTable();
            obj.updateCurEpochTable();
        end
        
        function initializeCurEpochTable(obj)
            props = [' ', obj.allKeys];
            columnFormat = {props, 'char', props, 'char'};
            set(obj.handles.curEpochTable,'ColumnFormat',columnFormat);
            
            tablePos = get(obj.handles.curEpochTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.25);
            col2W = round(tableWidth*.25);
            col3W = round(tableWidth*.25);
            col4W = round(tableWidth*.25);
            set(obj.handles.curEpochTable,'ColumnWidth',{col1W, col2W, col3W, col4W});
            obj.updateCurEpochTable();
        end
        
        function updateCurEpochTable(obj)            
            D = get(obj.handles.curEpochTable,'Data');
            z=1;
            for i=1:size(D,1)
                for col = [1, 3]
                    if ~isempty(D{i,col})
                        value = obj.cellData.epochs(obj.dataSet(obj.selectedEpochInd)).get(D{i,col});
                        D{i,col+1} = num2str(value, '%d');
%                         value;
                        obj.curViewParams{z} = D{i,col};
                        obj.curViewLocations{z} = [i,col];
                        z=z+1;
                    end
                end
            end
            set(obj.handles.curEpochTable,'Data', D);
        end
        
        function initializeFilterResultsTable(obj)
            tablePos = get(obj.handles.filterResultsTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.25);
            col2W = round(tableWidth*.75);
            set(obj.handles.filterResultsTable,'ColumnWidth',{col1W, col2W});
            obj.updateFilterResultsTable();
        end
        
        function updateFilterResultsTable(obj)
            set(obj.handles.filterResultsText, ...
                'String', ['Parameters With Multiple Values: ' num2str(length(obj.dataSet)) ' Epochs']);
            [params, vals] = obj.cellData.getNonMatchingParamVals(obj.dataSet);
            numParams = length(params);
            D = cell(numParams,2);
            quickParamListData = {};
            quickParamListStrings = {};
            quickParamIndex = 1;
            for i=1:numParams
                D{i,1} = params{i};
                if length(vals{i}) == 1
                    D{i,2} = vals{i};
                else
                    D{i,2} = makeDelimitedString(vals{i});
                end

                if length(vals{i}) < 6
                    v = vals{i};
                    for vi = 1:length(v)
                        if iscell(v)
                            quickParamListData{quickParamIndex,2} = v{vi};
                        else
                            quickParamListData{quickParamIndex,2} = v(vi);
                        end
                        quickParamListData{quickParamIndex,1} = params{i};
                        if ischar(quickParamListData{quickParamIndex,2})
                            quickParamListStrings{1,quickParamIndex} = sprintf('%s: %s', quickParamListData{quickParamIndex,1}, quickParamListData{quickParamIndex,2});
                        else
                            quickParamListStrings{1,quickParamIndex} = sprintf('%s: %g', quickParamListData{quickParamIndex,1}, quickParamListData{quickParamIndex,2});
                        end
                        quickParamIndex = quickParamIndex + 1;
                    end
                end
            end
            set(obj.handles.filterResultsTable, 'Data', D);
            
            % update string for dropdown quick filter
            if quickParamIndex == 1
                obj.handles.filterParamsMenu.String = {'No params'};
            else
                obj.handles.filterParamsMenu.String = horzcat('Quick change params', quickParamListStrings);
            end
            obj.quickParamsFilterList = quickParamListData;
        end
        
        function initializeFilterTable(obj)
            props = [' ', obj.allKeys];
            columnFormat = {props, obj.operators, 'char'};
            set(obj.handles.filterTable,'ColumnFormat',columnFormat);
            
            %filtTable
            tablePos = get(obj.handles.filterTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.4);
            col2W = round(tableWidth*.10);
            col3W = round(tableWidth*.4);
            set(obj.handles.filterTable,'ColumnWidth',{col1W, col2W, col3W});
            set(obj.handles.filterTable, 'Data', cell(12,3));
            
            set(obj.handles.filterPatternEdit, 'String', '');
            
            % initialize the list of display names dropdown for quick filter construction
            displayNames = unique(obj.cellData.getEpochVals('displayName', obj.dataSet));
            obj.handles.filterDisplayNamesMenu.String = horzcat('Quick change display name', displayNames);
            voltages = num2cell(unique(obj.cellData.getEpochVals('ampHoldSignal', obj.dataSet)));
            obj.handles.filterVoltagesMenu.String = horzcat('Quick change voltages', voltages);
            
        end
        
        function diaryPlotClick(obj)
            epochTimes = obj.cellData.getEpochVals('epochStartTime', obj.dataSet);
            epochNums = obj.cellData.getEpochVals('epochNum', obj.dataSet);
            a = get(obj.handles.diaryXMenu,'Value');
            s = get(obj.handles.diaryXMenu,'String');
            xmode = s(a);
            if strcmp(xmode, 'epochNum')
                xvals = epochNums;
            else
                xvals = epochTimes;
            end                
            p = get(obj.handles.diaryPlotAxes,'CurrentPoint');
            xval = p(1,1);
            [~, closestInd] = min(abs(xval - xvals));
            obj.selectedEpochInd = closestInd;
            obj.updateDiaryPlot();
            obj.updateDataPlot();
            obj.updateCurEpochTable();
        end
        
        function decrementEpochInd(obj)
            obj.selectedEpochInd = max(1,  obj.selectedEpochInd-1);
            obj.updateDataPlot();
            obj.updateDiaryPlot();
            obj.updateCurEpochTable();
        end
        
        function incrementEpochInd(obj)
            obj.selectedEpochInd = min(length(obj.dataSet),  obj.selectedEpochInd+1);
            obj.updateDataPlot();
            obj.updateDiaryPlot();
            obj.updateCurEpochTable();
        end
        
        function saveViewFunc(obj)
            [fname,fpath] = uiputfile('*.mat','Save view file...','~/analysis/views/');
            viewParams = obj.curViewParams;
            viewLocations = obj.curViewLocations;
            save(fullfile(fpath, fname), 'viewParams', 'viewLocations');            
        end
        
        function saveDataSetFunc(obj)
           displayName = obj.cellData.epochs(obj.dataSet(1)).attributes('displayName'); % fill in dataset name guess
           displayName = strrep(displayName, ' ', '');
           saveName = inputdlg('Enter data set name','',1,{displayName});
           if isempty(saveName)
               return
           end
           saveName = saveName{1}; %inputdlg returns cell instead of string
           obj.cellData.savedDataSets(saveName) = obj.dataSet;
           obj.epochsInDataSets = unique([obj.epochsInDataSets obj.dataSet]); %todo - look for double-counted epochs?
           obj.updateDataSetMenu();
           %save filter
           filtStruct.filterData = get(obj.handles.filterTable,'Data');
           filtStruct.filterPatternString = get(obj.handles.filterPatternEdit, 'String');
           obj.cellData.savedFilters(saveName) = filtStruct;
           %to reflect change in epochsIndDataSets status
           obj.updateDiaryPlot();
           %save cellData
           obj.saveCellData();
        end
        
        function makeDisplayNameFilter(obj)
            filterTableData = get(obj.handles.filterTable, 'Data');
            
            displayNameList = get(obj.handles.filterDisplayNamesMenu,'String');
            ind = get(obj.handles.filterDisplayNamesMenu,'Value');
            obj.handles.filterDisplayNamesMenu.Value = 1;
            if ind == 1
                return
            end
            
            displayName = displayNameList{ind};
            filterTableData(1,:) = {'displayName', '==', displayName};
            set(obj.handles.filterTable, 'Data', filterTableData);
            
            obj.updateFilter();
            if strcmp(obj.handles.filterPatternEdit.String, '')
                set(obj.handles.filterPatternEdit, 'String', '@1');
            end
            obj.updateFilter();
        end
        
        
        function makeVoltagesFilter(obj)
            voltageList = get(obj.handles.filterVoltagesMenu,'String');
            ind = get(obj.handles.filterVoltagesMenu,'Value');
            obj.handles.filterVoltagesMenu.Value = 1;
            if ind == 1
                if strcmp(obj.handles.filterPatternEdit.String, '@1 && @2')
                    set(obj.handles.filterPatternEdit, 'String', '@1');
                elseif strcmp(obj.handles.filterPatternEdit.String, '@1 && @2 && @3')
                    set(obj.handles.filterPatternEdit, 'String', '@1 && @3');
                end
                obj.handles.filterTable.Data(2,:) = {'','',''};
                return
            end
            voltage = voltageList{ind};
            
            filterTableData = get(obj.handles.filterTable, 'Data');          
            filterTableData(2,:) = {'ampHoldSignal', '==', voltage};
            set(obj.handles.filterTable, 'Data', filterTableData);
            
            obj.updateFilter();
            if strcmp(obj.handles.filterPatternEdit.String, '@1')
                set(obj.handles.filterPatternEdit, 'String', '@1 && @2');
            end
            if strcmp(obj.handles.filterPatternEdit.String, '@1 && @3')
                set(obj.handles.filterPatternEdit, 'String', '@1 && @2 && @3');
            end
            obj.updateFilter();
        end
        
        function makeParamsFilter(obj)
            ind = get(obj.handles.filterParamsMenu,'Value');
            obj.handles.filterParamsMenu.Value = 1;
            if ind == 1
                if strcmp(obj.handles.filterPatternEdit.String, '@1 && @3')
                    set(obj.handles.filterPatternEdit, 'String', '@1');
                elseif strcmp(obj.handles.filterPatternEdit.String, '@1 && @2 && @3')
                    set(obj.handles.filterPatternEdit, 'String', '@1 && @2');
                end
                obj.handles.filterTable.Data(3,:) = {'','',''};
                obj.updateFilter();
                return
            end
            param = obj.quickParamsFilterList(ind - 1, :);
            
            filterTableData = get(obj.handles.filterTable, 'Data');
            filterTableData(3,:) = {param{1}, '==', num2str(param{2})};
            set(obj.handles.filterTable, 'Data', filterTableData);
            obj.updateFilter();

            obj.updateFilter();
            if strcmp(obj.handles.filterPatternEdit.String, '@1')
                set(obj.handles.filterPatternEdit, 'String', '@1 && @3');
            end            
            
            if strcmp(obj.handles.filterPatternEdit.String, '@1 && @2')
                set(obj.handles.filterPatternEdit, 'String', '@1 && @2 && @3');
            end
            obj.updateFilter();
        end
        
        function loadViewFunc(obj)
            [fname,fpath] = uigetfile('*.mat','Load view file...','~/analysis/views/');            
            load(fullfile(fpath, fname), 'viewParams', 'viewLocations'); 
            obj.curViewParams = viewParams;
            obj.curViewLocations = viewLocations;
            D = cell(6,4);
            for i=1:length(obj.curViewParams)
                D{obj.curViewLocations{i}(1), obj.curViewLocations{i}(2)} = obj.curViewParams{i};
            end
            set(obj.handles.curEpochTable,'Data', D)
            obj.updateCurEpochTable();
        end
        
        function resetView(obj)
            obj.handles.dataSetsMenu.Value = 1;
            obj.dataSet = 1:obj.cellData.get('Nepochs');
            obj.initializeFilterTable();
            obj.initializeFilterResultsTable();
            obj.selectedEpochInd = 1;
            obj.updateDataPlot();
            obj.updateDiaryPlot();
            obj.updateCurEpochTable();            
        end
        
        function loadDataSet(obj)
            dataSetNames = get(obj.handles.dataSetsMenu,'String');
            ind = get(obj.handles.dataSetsMenu,'Value');
            if ind == 1 %reset
                obj.dataSet = 1:obj.cellData.get('Nepochs');
                obj.initializeFilterTable();
                obj.initializeFilterResultsTable();

            else
                setName = dataSetNames{ind};
                obj.dataSet = obj.cellData.savedDataSets(setName);
                %load filter
                if ~isempty(obj.cellData.savedFilters)
                    if  obj.cellData.savedFilters.isKey(setName)
                        filtStruct = obj.cellData.savedFilters(setName);
                        set(obj.handles.filterTable,'Data',filtStruct.filterData);
                        set(obj.handles.filterPatternEdit, 'String', filtStruct.filterPatternString);
                        obj.updateFilter();
                    end
                end
                obj.updateFilterResultsTable();
                
            end
            obj.selectedEpochInd = 1;
            obj.updateDataPlot();
            obj.updateDiaryPlot();
            obj.updateCurEpochTable();
        end
        
        function renameDataSet(obj) %todo: make filter names stay in sync!!!
            dataSetNames = get(obj.handles.dataSetsMenu,'String');
            ind = get(obj.handles.dataSetsMenu,'Value');
            if ind==1
                warndlg('You must select a data set');
            else
                saveName = inputdlg('Enter new data set name', 'New name', 1, {dataSetNames{ind}});
                if isempty(saveName)
                    return
                end
                saveName = saveName{1}; %inputdlg returns cell instead of string
                remove(obj.cellData.savedDataSets, dataSetNames{ind});
                obj.cellData.savedDataSets(saveName) = obj.dataSet;
                obj.updateDataSetMenu();
                dataSetNames = get(obj.handles.dataSetsMenu,'String');
                ind = strmatch(saveName, dataSetNames);
                set(obj.handles.dataSetsMenu,'Value', ind);
            end
            obj.saveCellData();
        end
        
        function deleteDataSet(obj)
            dataSetNames = get(obj.handles.dataSetsMenu,'String');
            ind = get(obj.handles.dataSetsMenu,'Value');
            if ind==1
                warndlg('You must select a data set');
            else
                remove(obj.cellData.savedDataSets, dataSetNames{ind});
                obj.epochsInDataSets = setdiff(obj.epochsInDataSets, obj.dataSet); %todo - look for double-counted epochs?
                set(obj.handles.dataSetsMenu,'Value', 1);                
                obj.updateDataSetMenu();                
            end
            obj.saveCellData();
        end
        
        function updateDataSetMenu(obj)
            dataSetKeys = obj.cellData.savedDataSets.keys;
            set(obj.handles.dataSetsMenu,'String', ['Data sets...' dataSetKeys]);
        end
        
        function addParamToEpoch(obj)
            paramName = get(obj.handles.paramNameEdit, 'String');
            paramVal = get(obj.handles.paramValEdit, 'String');
            curEpoch = obj.cellData.epochs(obj.dataSet(obj.selectedEpochInd));
            if isKey(curEpoch.attributes, paramName)
                answer = questdlg('Overwrite current parameter value?', 'Overwrite warning:', 'No','Yes','Yes');
                if strcmp(answer, 'Yes')
                    if evalsToNumeric(paramVal)
                        curEpoch.attributes(paramName) = eval(paramVal);
                    else
                        curEpoch.attributes(paramName) = paramVal;
                    end
                end
            else
                if evalsToNumeric(paramVal)
                    curEpoch.attributes(paramName) = eval(paramVal);
                else
                    curEpoch.attributes(paramName) = paramVal;
                end
            end
            obj.saveCellData();
            obj.updateParamsList();
            obj.updateCurEpochTable();
            obj.updateFilterResultsTable();
        end
        
        function addParamToDataSet(obj)
            paramName = get(obj.handles.paramNameEdit, 'String');
            paramVal = get(obj.handles.paramValEdit, 'String');
            addParam = false;
            if strmatch(paramName, obj.allKeys)
                answer = questdlg('Overwrite current parameter value?', 'Overwrite warning:', 'No','Yes','Yes');
                if strcmp(answer, 'Yes')
                    addParam = true;
                end
            else
                addParam = true;
            end
            if addParam
                for i=1:length(obj.dataSet)
                    curEpoch = obj.cellData.epochs(obj.dataSet(i));
                    if evalsToNumeric(paramVal)
                        curEpoch.attributes(paramName) = eval(paramVal);
                    else
                        curEpoch.attributes(paramName) = paramVal;
                    end
                end
                fprintf('Added param %s value %s\n', paramName, paramVal);
            end
            obj.saveCellData();
            obj.updateParamsList();
            obj.updateCurEpochTable();
            obj.updateFilterResultsTable();
        end
        
        function deleteParamFromEpoch(obj)
            paramName = get(obj.handles.paramNameEdit, 'String');
            if isempty(strmatch(paramName, obj.allKeys))
                msgbox(['Parameter ' paramName ' not found'], 'Parameter not found', 'error');
            else
                answer = questdlg(['Delete parameter ' paramName ' from this epoch?'], 'Are you sure?', 'No','Yes','Yes');
                if strcmp(answer, 'Yes')
                    curEpoch = obj.cellData.epochs(obj.dataSet(obj.selectedEpochInd));
                    remove(curEpoch.attributes, paramName);
                end
            end
            obj.saveCellData();
            obj.updateParamsList();
            obj.updateCurEpochTable();
            obj.updateFilterResultsTable();
        end
        
        function deleteParamFromDataSet(obj)
            paramName = get(obj.handles.paramNameEdit, 'String');
            if isempty(strmatch(paramName, obj.allKeys))
                msgbox(['Parameter ' paramName ' not found'], 'Parameter not found', 'error');
            else
                answer = questdlg(['Delete parameter ' paramName ' from all epochs in this data set?'], 'Are you sure?', 'No','Yes','Yes');
                if strcmp(answer, 'Yes')
                    for i=1:length(obj.dataSet)
                        curEpoch = obj.cellData.epochs(obj.dataSet(i));
                        remove(curEpoch.attributes, paramName);
                    end
                end
            end
            obj.updateParamsList();
            obj.updateCurEpochTable();
            obj.updateFilterResultsTable();
        end
        
        
        function chooseSaveLocation(obj)
            [fname, fpath] = uiputfile('*.mat', 'Choose save location for data file...', ['~/analysis/cellData/' obj.cellData.rawfilename]);
            fname_full = fullfile(fpath, fname);
            obj.cellData.savedFileName = fname_full;
            set(obj.fig, 'Name',['CellDataCurator: ' obj.cellData.savedFileName]);
        end
        
        function saveCellData(obj)
            set(obj.fig, 'Name', 'Saving');
            drawnow;
            saveAndSyncCellData(obj.cellData);
            set(obj.fig, 'Name', 'Saved');
            drawnow;            
        end
        
        function saveFilter(obj)
            [fname,fpath] = uiputfile('*.mat','Save view file...','~/analysis/filters/');
            filterData = get(obj.handles.filterTable,'Data');
            filterPatternString = get(obj.handles.filterPatternEdit, 'String');
            save(fullfile(fpath, fname), 'filterData', 'filterPatternString');      
        end
        
        function loadFilter(obj)
            [fname,fpath] = uigetfile('*.mat','Load view file...','~/analysis/filters/');
            if ~isempty(fname) %if selected something
                load(fullfile(fpath, fname), 'filterData', 'filterPatternString');
                set(obj.handles.filterTable,'Data',filterData);
                set(obj.handles.filterPatternEdit, 'String', filterPatternString);
                obj.updateFilter();
                obj.applyFilter();
            end
        end
        
        function resizeWindow(obj)
            %filtTable
            if isfield(obj.handles, 'filterTable')
            tablePos = get(obj.handles.filterTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.4);
            col2W = round(tableWidth*.10);
            col3W = round(tableWidth*.4);
            set(obj.handles.filterTable,'ColumnWidth',{col1W, col2W, col3W});
            end
            
            %filter results table
            if isfield(obj.handles, 'filterResultsTable')
            tablePos = get(obj.handles.filterResultsTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.25);
            col2W = round(tableWidth*.75);
            set(obj.handles.filterResultsTable,'ColumnWidth',{col1W, col2W});
            end
            
            %curEpochTable
            if isfield(obj.handles, 'curEpochTable')
            tablePos = get(obj.handles.curEpochTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.25);
            col2W = round(tableWidth*.25);
            col3W = round(tableWidth*.25);
            col4W = round(tableWidth*.25);
            set(obj.handles.curEpochTable,'ColumnWidth',{col1W, col2W, col3W, col4W});
            end
        end
        
    end
    
end

