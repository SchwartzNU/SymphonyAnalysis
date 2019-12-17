
classdef CellMorphologyGUI < handle
    properties
        selectedRows
    end
    
    properties (Hidden)
        fig %figure handle
        handles %all the rest of the handles
    end
    
    properties (Hidden, Constant)
        
        %imageRoot_2P = 'down/Volumes/fsmresfiles/Images/2P';
    end
    
    methods
        function obj = CellMorphologyGUI()
            obj.buildUIComponents();
            obj.resizeWindow();
            obj.loadCells();
        end
        
        function buildUIComponents(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         'Cell Morphology GUI: ', ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ... %revisit this
                'ResizeFcn', @(uiobj,evt)obj.resizeWindow);
            
            %main grid layout
            L_main = uiextras.HBoxFlex('Parent', obj.fig);
            
            %2 main Panels
            L_left = uiextras.VBoxFlex('Parent', L_main);
            L_right = uiextras.VBoxFlex('Parent', L_main);
            
            set(L_main, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Padding', 10, ...
                'Spacing', 10, ...
                'Widths', [-1 -1]);
            
            %Panels within each left and right main panel
            %left
            obj.handles.L_cellsTablePanel = uiextras.BoxPanel('Parent', L_left, ...
                'Title', 'Cell table', ...
                'FontSize', 12);
            L_cellsTableControlsPanel = uiextras.BoxPanel('Parent', L_left, ...
                'Title', 'Cell table controls', ...
                'FontSize', 12);
            %right
            obj.handles.L_plotsPanel = uipanel('Parent', L_right);
            
            obj.handles.statsTable = uitable('Parent', L_right, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'Property', 'Value'}, ...
                'RowName', [], ...
                'ColumnEditable', logical([0 0]), ...
                'Data', cell(5,2), ...
                'TooltipString', 'table of properties for currently selected node');
            
            L_plotControlsPanel = uiextras.BoxPanel('Parent', L_right, ...
                'Title', 'Plot controls', ...
                'FontSize', 12);
            
            %set layout for left and right
            set(L_left, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Padding', 5, ...
                'Spacing', 10, ...
                'Heights', [-4 -1]);
            set(L_right, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Padding', 5, ...
                'Spacing', 10, ...
                'Heights', [-3 -1 -1]);
            
            %Cells table
            obj.handles.cellsTable = uitable('Parent', obj.handles.L_cellsTablePanel, ...
                'Units',    'pixels', ...
                'ColumnWidth', {100, 100, 50, 50, 50, 50, 200}, ... %initial, gets reset in resizeWindow
                'FontSize', 12, ...
                'ColumnName', {'Cell name', 'Type', 'Type doubt' 'Traced', 'ChAT surface', 'Analyzed', 'Notes'}, ...
                'ColumnFormat', {'char', 'char', 'logical' 'logical', 'logical', 'logical', 'char'}, ...
                'RowName', {}, ...
                'ColumnEditable', logical([0 0 0 1 1 0 1]), ...
                'CellSelectionCallback', @(uiobj, evt)obj.cellSelection(evt), ...
                'CellEditCallback', @(uiobj, evt)obj.cellNotesEdit(evt), ...
                'Data', cell(50,5)); %will fill this
            
            %Cells table controls
            L_cellsTableControls = uiextras.HBox('Parent', L_cellsTableControlsPanel, ...
                'units', 'normalized', ....
                'Position', [0 0 1 1]);
            
            sortBy_text =  uicontrol('Parent', L_cellsTableControls, ...
                'Style', 'text', ...
                'FontSize', 12, ...
                'String', 'Sort by');

            obj.handles.sortMenu = uicontrol('Parent', L_cellsTableControls, ...
                'Style', 'popupmenu', ....
                'String', obj.handles.cellsTable.get('ColumnName'), ...
                'Value', 1, ...
                'Callback', @(uiobj,evt)obj.sortCells());
            
            obj.handles.reloadCells_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsTableControls, ...
                'FontSize', 12, ...
                'String', 'Reload cells', ...
                'Callback', @(uiobj,evt)obj.loadCells());
            
            obj.handles.cellsToProject_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsTableControls, ...
                'FontSize', 12, ...
                'String', 'Cells to LabDataGUI project', ...
                'Callback', @(uiobj,evt)obj.cellsToProject());
            
            obj.handles.runAnalyzer_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_cellsTableControls, ...
                'FontSize', 12, ...
                'String', 'Run analyzer on selected cells', ...
                'Callback', @(uiobj,evt)obj.runAnalyzer());
            
            set(L_cellsTableControls, ...
                'Padding', 5, ...
                'Spacing', 10, ...
                'Widths', [40 -1 -1 -1 -1]);
            
            %plot controls
            L_plotControls = uiextras.HBox('Parent', L_plotControlsPanel, ...
                'units', 'normalized', ....
                'Position', [0 0 1 1]);
            
            obj.handles.stratNormalize_toggle = uicontrol('Style', 'togglebutton', ...
                'Parent', L_plotControls, ...
                'FontSize', 12, ...
                'String', 'Normalize stratification', ...
                'Callback', @(uiobj,evt)obj.updatePlots());
            
            obj.handles.exportStrat_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_plotControls, ...
                'FontSize', 12, ...
                'String', 'Export stratification', ...
                'Callback', @(uiobj,evt)obj.exportStrat());
            
            obj.handles.exportTrees_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_plotControls, ...
                'FontSize', 12, ...
                'String', 'Export trees', ...
                'Callback', @(uiobj,evt)obj.exportTrees());
            
            obj.handles.exportDataTable_button = uicontrol('Style', 'pushbutton', ...
                'Parent', L_plotControls, ...
                'FontSize', 12, ...
                'String', 'Export data table', ...
                'Callback', @(uiobj,evt)obj.exportDataTable());
    
            set(L_plotControls, ...
                'Padding', 5, ...
                'Spacing', 10, ...
                'Widths', [-1 -1 -1 -1]);
          
        end
        
        function resizeWindow(obj)
            if isfield(obj.handles, 'L_cellsTablePanel')
                temp = obj.handles.L_cellsTablePanel.get('position');
                panelWidth = temp(3);
                if isfield(obj.handles, 'cellsTable')
                    temp = obj.handles.cellsTable.get('position');
                    temp(3) = panelWidth;
                    obj.handles.cellsTable.set('position', temp);
                    obj.handles.cellsTable.set('ColumnWidth', num2cell(panelWidth.*[0.2 0.2 0.05 0.05 0.05 0.05 0.37]));
                end
            end
            if isfield(obj.handles, 'statsTable')
                temp = obj.handles.statsTable.get('position');
                temp(3) = panelWidth;
                obj.handles.statsTable.set('position', temp);
                obj.handles.statsTable.set('ColumnWidth', num2cell(panelWidth.*[0.45 0.45]));
            end
        end
        
        function loadCells(obj)
            global SERVER
            if exist([SERVER 'Images/Confocal'], 'file')
                imageRoot_confocal = [SERVER 'Images/Confocal'];
            else
                error('Cannot connect to Images/Confocal folder on Server')
            end
            
            %loads cells into data table
            D = dir(imageRoot_confocal); %only confocal for now
            L = length(D);
            z = 1;
            tableData = cell(L, 7);
            for i=1:L
                curName = D(i).name;
                if ~isempty(str2num(curName(1))) %#ok<ST2NM> %numeric so it is a cell name
                    tableData{z, 1} = curName;
                    cellData = loadAndSyncCellData(curName);
                    if ~isempty(cellData) %has cellData
                        tableData{z, 2} = cellData.cellType;
                        if cellData.tags.isKey('CelltypeDoubt')
                            if cellData.tags('CelltypeDoubt') > 0
                                tableData{z, 3} = true;
                            end
                        else
                            tableData{z, 3} = false;
                        end
                        tableData{z, 7} = cellData.notes;
                    else %does not have cellData
                        tableData{z, 2} = 'cellData not found';
                        tableData{z, 3} = false;
                        tableData{z, 7} = '';
                    end
                    %in all cases
                    cellFolderD = dir([imageRoot_confocal filesep curName]);
                    cellFolderD_names = {cellFolderD.name};
                    if ~isempty(strmatch([curName '.swc'], cellFolderD_names, 'exact')) %#ok<MATCH3>
                        tableData{z, 4} = true;
                    else
                        tableData{z, 4} = false;
                    end
                    if ~isempty(strmatch([curName '_CHATsurface.mat'], cellFolderD_names, 'exact')) %#ok<MATCH3>
                        tableData{z, 5} = true;
                    else
                        tableData{z, 5} = false;
                    end                    
                    if ~isempty(strmatch([curName '_morphologyData.mat'], cellFolderD_names, 'exact')) %#ok<MATCH3>
                        tableData{z, 6} = true;
                    else
                        tableData{z, 6} = false;
                    end
                    
                    z = z+1;
                end
            end
            z = z-1;
            tableData = tableData(1:z, :);
            obj.handles.cellsTable.set('Data', tableData);
        end
        
        function cellsToProject(obj)
            global SERVER;
            global ANALYSIS_FOLDER;
            imageRoot_confocal = [SERVER 'Images/Confocal'];
            
            projectName = inputdlg('Enter project name');
            projectName = projectName{1};
            if ~isempty(projectName)
                tableData = obj.handles.cellsTable.get('Data');
                cellNames = tableData(obj.selectedRows, 1);
                cellNames = mergeCellNames(cellNames);
                
                if exist([ANALYSIS_FOLDER 'Projects' filesep  projectName])
                    rmdir([ANALYSIS_FOLDER 'Projects' filesep  projectName], 's');
                end
                eval(['!mkdir ' ANALYSIS_FOLDER 'Projects' filesep  projectName]);
                fid = fopen([ANALYSIS_FOLDER, 'Projects', filesep, projectName, filesep, 'cellNames.txt'], 'w');
                
                for i=1:length(cellNames)
                    if ~isempty(cellNames{i})
                        fprintf(fid, '%s\n', cellNames{i});
                    end
                end
                fclose(fid);
            end
            
        end
        
        function updateDataTable(obj)
            global SERVER
            imageRoot_confocal = [SERVER 'Images/Confocal'];
            tableData = obj.handles.cellsTable.get('Data');
            L = length(obj.selectedRows);
            %clear previous stats from table
            statsData = {};
            set(obj.handles.statsTable, 'Data', statsData); 
            %add new stats
            if L==1 %single selection
                curName = tableData{obj.selectedRows(1), 1};
                if  tableData{obj.selectedRows(1), 6}
                    curDir = [imageRoot_confocal filesep curName filesep];
                    morphology_fname = [curName '_morphologyData.mat'];
                    %load data
                    load([curDir morphology_fname], 'outputStruct');
                    fnames = fieldnames(outputStruct);
                    Nfields = length(fnames);
                    z=1;

                    for j=1:Nfields
                        curVal = outputStruct.(fnames{j});
                        if isscalar(curVal)
                            statsData{z,1} = fnames{j};
                            statsData{z,2} = curVal;
                            z=z+1;
                        end
                    end
                end
                set(obj.handles.statsTable, 'Data', statsData);                
            else
               %multiple selection: what do we do here?
               
            end
        end
                
        function updatePlots(obj)
            global SERVER
            imageRoot_confocal = [SERVER 'Images/Confocal'];
            tableData = obj.handles.cellsTable.get('Data');
            %clear plots
            ch = get(obj.handles.L_plotsPanel, 'children');
            for i=1:length(ch)
                delete(ch(i));            
            end
            
            doNorm = obj.handles.stratNormalize_toggle.get('Value');

            %if length(obj.selectedRows) == 1 %one cell selected

            L = length(obj.selectedRows);
            allNames = {};
            didPlot = false;
            for i=1:L                
                if tableData{obj.selectedRows(i), 6} %analyzed
                    didPlot = true;
                    curName = tableData{obj.selectedRows(i), 1};
                    allNames = [allNames, curName];
                    curDir = [imageRoot_confocal filesep curName filesep];
                    morphology_fname = [curName '_morphologyData.mat'];
                    %load data
                    load([curDir morphology_fname], 'outputStruct');
                    
                    %plot stratification
                    if i==1
                        obj.handles.strat_ax = axes('Parent', obj.handles.L_plotsPanel, ...
                            'Units', 'normalized', ...
                            'Position', [0.05 0.4 .4 .55]);
                    end
                    if doNorm 
                        p(i) = plot(obj.handles.strat_ax, outputStruct.strat_x, outputStruct.strat_y_norm);
                    else
                        p(i) = plot(obj.handles.strat_ax, outputStruct.strat_x, outputStruct.strat_y);
                    end
                    hold(obj.handles.strat_ax, 'on');
                    line([0 0], obj.handles.strat_ax.get('Ylim'), 'Parent', obj.handles.strat_ax, 'Color', 'c');
                    line([1 1], obj.handles.strat_ax.get('Ylim'), 'Parent', obj.handles.strat_ax, 'Color', 'm');
                    xlabel(obj.handles.strat_ax, 'Relative IPL depth');
                    title(obj.handles.strat_ax, 'Stratification profile');
                    if doNorm 
                         ylabel(obj.handles.strat_ax, 'Dendrite length (norm.)');
                    else
                         ylabel(obj.handles.strat_ax, 'Dendrite length (microns)');
                    end
                    if i>1 && i==L
                       legend(obj.handles.strat_ax, p, allNames);
                    end
                    %hold(obj.handles.strat_ax, 'off');
                    
                    %plot dendrites
                    startX = 0.55;
                    startY = 0.4;
                    totalW = 0.4;
                    totalH = 0.55;
                    
                    switch L
                        case 1                        
                            obj.handles.dend_ax(i) = axes('Parent', obj.handles.L_plotsPanel, ...
                                'Units', 'normalized', ...
                                'Position', [startX startY totalW totalH]);
                        case 2
                            obj.handles.dend_ax(i) = axes('Parent', obj.handles.L_plotsPanel, ...
                                'Units', 'normalized', ...
                                'Position', [startX + 1.1 * totalW/2 * (i-1), startY, 0.9 * totalW/2, totalH/2]);
                        case {3, 4}
                            if i<3
                                obj.handles.dend_ax(i) = axes('Parent', obj.handles.L_plotsPanel, ...
                                    'Units', 'normalized', ...
                                    'Position', [startX + 1.1 * totalW/2 * (i-1), startY, 0.9 * totalW/2, totalH/2]);
                            elseif i>=3
                                obj.handles.dend_ax(i) = axes('Parent', obj.handles.L_plotsPanel, ...
                                    'Units', 'normalized', ...
                                    'Position', [startX + 1.1 * totalW/2 * (i-3), startY + 1.1 * totalH/2, 0.9 * totalW/2, totalH/2]);
                            end
                        otherwise
                            %too many, don't plot anything
                    end
 
                    if isempty(outputStruct.ON_OFF_division); %monostratified
                        scatter(obj.handles.dend_ax(i), outputStruct.allXYpos(:,1), outputStruct.allXYpos(:,2), 'k.');
                        hold(obj.handles.dend_ax(i), 'on');
                        plot(obj.handles.dend_ax(i), outputStruct.allXYpos(outputStruct.boundaryPoints,1), outputStruct.allXYpos(outputStruct.boundaryPoints,2), 'k-');
                    else  %bistratified
                        ON_ind = find(outputStruct.allZpos<=outputStruct.ON_OFF_division);
                        OFF_ind = find(outputStruct.allZpos>outputStruct.ON_OFF_division);
                        scatter(obj.handles.dend_ax(i), outputStruct.allXYpos(ON_ind,1), outputStruct.allXYpos(ON_ind,2), 'g.')
                        hold(obj.handles.dend_ax(i), 'on');
                        plot(obj.handles.dend_ax(i), outputStruct.allXYpos(ON_ind(outputStruct.boundaryPoints_ON),1), outputStruct.allXYpos(ON_ind(outputStruct.boundaryPoints_ON),2), 'g-');
                        scatter(obj.handles.dend_ax(i), outputStruct.allXYpos(OFF_ind,1), outputStruct.allXYpos(OFF_ind,2), 'r.')
                        plot(obj.handles.dend_ax(i), outputStruct.allXYpos(OFF_ind(outputStruct.boundaryPoints_OFF),1), outputStruct.allXYpos(OFF_ind(outputStruct.boundaryPoints_OFF),2), 'r-');
                    end
                    axis(obj.handles.dend_ax(i), 'equal');
                    if L==1
                        xlabel(obj.handles.dend_ax(i), 'Microns');
                        ylabel(obj.handles.dend_ax(i), 'Microns');
                        title(obj.handles.dend_ax(i), 'Dendritic tree');
                    else
                        title(obj.handles.dend_ax(i), curName);
                    end
                    hold(obj.handles.dend_ax(i), 'off');
                else %not analyzed, so do nothing
                    
                end
            end
            if didPlot
                %set all limits the same for dend. plots
                maxLim = 0;
                for i=1:L
                    curLim = obj.handles.dend_ax(i).get('Xlim');
                    curLim = curLim(2);
                    if curLim > maxLim
                        maxLim = curLim;
                    end
                end
                newLim = [-maxLim, maxLim];
                for i=1:L
                    obj.handles.dend_ax(i).set('Xlim', newLim);
                    obj.handles.dend_ax(i).set('Ylim', newLim);
                end
            end
        end
        
        function cellSelection(obj, eventData)
            obj.selectedRows = eventData.Indices(:, 1);
            obj.updateDataTable();
            obj.updatePlots();
        end
        
        function runAnalyzer(obj)
            global SERVER
            imageRoot_confocal = [SERVER 'Images/Confocal'];
            
            tableData = obj.handles.cellsTable.get('Data');
            cellNames = tableData(obj.selectedRows, 1);
            
            for i=1:length(cellNames)
                curName = cellNames{i};                
                disp(['Analyzing cell ' curName]);                
                if tableData{obj.selectedRows(i), 4} %if traced
                    curDir = [imageRoot_confocal '/' curName '/'];
                    trace_fname = [curName '.swc'];
                    
                    if exist([curDir curName '.tif'], 'file')
                        image_fname = [curName '.tif'];
                    elseif exist([curDir curName '.nd2'], 'file')
                        image_fname = [curName '.nd2'];
                    else
                        fprintf('No .tif or .nd2 images found for %s on the server (%s) \n', curName, curDir)
                    end
                    morphology_fname = [curName '_morphologyData.mat'];
                    
                    %try
                        outputStruct = rgcAnalyzer([curDir trace_fname] ,[curDir image_fname]);
                        save([curDir morphology_fname], 'outputStruct');
                        tableData{obj.selectedRows(i), 5} = true; %set chat surface to true
                        tableData{obj.selectedRows(i), 6} = true; %set analyzed to true
                        obj.handles.cellsTable.set('Data', tableData);
                    %catch
                   %     disp(['Analysis error for cell ' curName]);
                   % end
                end
            end
        end
        
        function sortCells(obj)
            sortColumn = obj.handles.sortMenu.get('Value');
            temp = obj.handles.cellsTable.get('ColumnFormat');
            colType = temp{sortColumn};
            tableData = obj.handles.cellsTable.get('Data');
            if strcmp(colType, 'char')
                [~, ind] = sortrows(char(tableData{:,sortColumn}));
            else
                [~, ind] = sort([tableData{:,sortColumn}]);
            end
            tableData = tableData(ind, :);
            obj.handles.cellsTable.set('Data', tableData);
        end
        
        function exportStrat(obj)
            global IGOR_H5_folder
            global SERVER
            imageRoot_confocal = [SERVER 'Images/Confocal'];
            tableData = obj.handles.cellsTable.get('Data');
            L = length(obj.selectedRows);
            for i=1:L
                curName = tableData{obj.selectedRows(i), 1};
                curDir = [imageRoot_confocal filesep curName filesep];
                morphology_fname = [curName '_morphologyData.mat'];
                %load data
                load([curDir morphology_fname], 'outputStruct');
                %make output struct
                s.strat_x = outputStruct.strat_x;
                s.strat_y = outputStruct.strat_y;
                s.strat_y_norm = outputStruct.strat_y_norm;
                if i==1
                    %get filename
                    [h5name,pathname] = uiputfile('*.h5', 'Specify hdf5 export file for Igor', IGOR_H5_folder);            
                end
                if ~isempty(h5name)
                    %do export
                    datasetName = ['c' curName];
                    exportStructToHDF5(s, fullfile(pathname, h5name), datasetName);
                    %pause(1);
                end
            end
        end
        
        function exportDataTable(obj)
            
        end
        
        function exportTrees(obj)
            
        end
        
        function cellNotesEdit(obj, eventData)
            %put these notes in cellData
        end
    end
    
    
end