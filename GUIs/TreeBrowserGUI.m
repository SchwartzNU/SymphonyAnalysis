classdef TreeBrowserGUI < handle
    
    properties
        analysisTree
        guiTree
        rootNode
        handles
        plotSelectionTable %index is tree node index,
        %column 1 is analysis class (or 'leaf'),
        %column 2 is cell array of plot functions,
        %colums 3 stores your current preference for plot type
        
        cellDataFolder
        igorh5Folder
        iconpath = [matlabroot filesep 'toolbox' filesep 'matlab' filesep 'icons' filesep 'greencircleicon.gif'];
    end
    
    properties(Hidden)
        epochTags = containers.Map;
        curEpochIndex = [];
        curCellData = [];
    end
    
    properties(Constant)
        leafPlotMethods = {'plotEpochData'; 'plotMeanData'; 'plotSpikeRaster'; 'plotLeaf'}; %plotLeaf can be overwritten in analysis class
        generalPlotMethods = {'XYplotter_epochParams'; 'XYplotter_singleValParams'};
    end
    
    methods
        function obj = TreeBrowserGUI(analysisTree)
            global ANALYSIS_FOLDER
            global PREFERENCE_FILES_FOLDER
            obj.cellDataFolder = [ANALYSIS_FOLDER 'cellData' filesep];
            obj.igorh5Folder = [ANALYSIS_FOLDER 'Igorh5' filesep];
            if nargin==0
                [fname, pathname] = uigetfile([ANALYSIS_FOLDER filesep 'analysisTrees' filesep '*.mat'], 'Load analysisTree');
                load(fullfile(pathname, fname)); %loads analysisTree
            end
            
            %read in EpochTags.txt file
            fid = fopen([PREFERENCE_FILES_FOLDER filesep 'EpochTags.txt']);
            fline = 'temp';
            while ~isempty(fline)
                fline = fgetl(fid);
                if isempty(fline) || (isscalar(fline) && fline < 0)
                    break;
                end
                curVals = {};
                [curTagName, rem] = strtok(fline);
                z=1;
                while ~isempty(rem)
                    [cval, rem] = strtok(rem);
                    cval = strtrim(cval);
                    curVals{z} = cval;
                    z=z+1;
                end
                obj.epochTags(curTagName) = curVals;
            end
            fclose(fid);
            
            obj.analysisTree = analysisTree;
            obj.makePlotSelectionTable();
            obj.buildUI();
            
        end
        
        function buildUI(obj)
            s = obj.analysisTree.get(1).name;
            loc = strfind(s, ':');
            rootName = s(loc+1:end);
            if isfield(obj.analysisTree.get(1), 'device')
                if strcmp(obj.analysisTree.get(1).device, 'Amplifier_Ch1')
                    rootName = [rootName '-Ch1'];
                elseif strcmp(obj.analysisTree.get(1).device, 'Amplifier_Ch2')
                    rootName = [rootName '-Ch2'];
                end
            end
            
            obj.handles.fig = figure( ...
                'Name',         ['TreeBrowser: ' rootName], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'position',     [100, 100, 1200, 800], ...
                'Menubar',      'none', ...
                'ResizeFcn', @(uiobj,evt)obj.resizeWindow);
            
            %save and load in file menu
            obj.handles.fileMenu = uimenu(obj.handles.fig, 'Label', 'File');
            obj.handles.loadMenuItem = uimenu(obj.handles.fileMenu, 'Label', 'Load Tree', ...
                'Callback', @(uiobj,evt)obj.loadTree);
            obj.handles.saveMenuItem = uimenu(obj.handles.fileMenu, 'Label', 'Save Tree', ...
                'Callback', @(uiobj,evt)obj.saveTree);
            obj.handles.runAnalysisItem = uimenu(obj.handles.fileMenu, 'Label', 'Run analysis', ...
                'Callback', @(uiobj,evt)obj.runAnalysis);
            
            %epoch tags menu
            obj.handles.tagsMenu = uimenu(obj.handles.fig, 'Label', 'Epoch tags');
            k = obj.epochTags.keys;
            for i=1:length(k)
                obj.handles.tagMenuItems(i,1) = uimenu(obj.handles.tagsMenu, 'Label', k{i});
                vals = obj.epochTags(k{i});
                for j=1:length(vals)
                    obj.handles.tagMenuItems(i,j+1) = uimenu(obj.handles.tagMenuItems(i,1), 'Label', vals{j}, ...
                        'Callback', @(uiobj,evt)obj.setEpochTags(k{i}, vals{j}));
                end
                obj.handles.tagMenuItems(i,length(vals)+2) = uimenu(obj.handles.tagMenuItems(i,1), 'Label', 'Remove', ...
                    'Callback', @(uiobj,evt)obj.setEpochTags(k{i}, 'remove'));
            end
            
            obj.rootNode = uitreenode('v0', 1, rootName, obj.iconpath, false);
            obj.addChildren(1, obj.rootNode);
            obj.guiTree = uitree('v0', obj.handles.fig, ...
                'Root', obj.rootNode, ...
                'Position', [20 20 380 760]);
            
            set(obj.guiTree, 'NodeSelectedCallback', @(uiobj, evt)obj.onNodeSelected);
            
            L_right = uiextras.VBoxFlex('Parent', obj.handles.fig, ...
                'Units', 'Normalized', ...
                'Position', [.42 .02 .56 .96]);
            
            L_tables = uiextras.HBoxFlex('Parent', L_right, 'Spacing', 10);
            
            obj.handles.L_plotControls = uiextras.VBox('Parent', L_tables);
                        
            obj.handles.plotSelectionMenu = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'popupmenu', ...
                'String', {'none'}, ...
                'Tag', 'plotSelectionMenu', ...
                'Units', 'normalized', ...
                'Callback', @(uiobj, evt)obj.onPlotSelectionMenu);
            
            obj.handles.plotSelectionApplyAllButton = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to all nodes of this type', ...
                'Callback', @(uiobj, evt)obj.applyPlotSelection);
            
            obj.handles.nodeToMatlabButton = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'pushbutton', ...
                'String', 'Node data to command line', ...
                'Callback', @(uiobj, evt)obj.nodeToMatlab);
            
            obj.handles.nodeToIgorButton = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'pushbutton', ...
                'String', 'Node data to Igor', ...
                'Callback', @(uiobj, evt)obj.nodeToIgor);
            
            set(obj.handles.L_plotControls, 'Sizes', [-1, 40, 40, 40]);
            
            L_twoTables = uiextras.VBoxFlex('Parent', L_tables, 'Spacing', 10);
            
            L_nodePropsPanel = uiextras.VBox('Parent', L_twoTables);
            
            nodePropText = uicontrol('Parent', L_nodePropsPanel, ...
                'Style', 'text', ...
                'String', 'Node properties');
                        
            obj.handles.nodePropertiesTable = uitable('Parent', L_nodePropsPanel, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'Property', 'Value'}, ...
                'RowName', [], ...
                'ColumnEditable', logical([0 0]), ...
                'Data', cell(5,2), ...
                'TooltipString', 'table of properties for currently selected node');
            
            %set node prop table width 
            tablePos = get(obj.handles.nodePropertiesTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.5);
            col2W = round(tableWidth*.5);
            set(obj.handles.nodePropertiesTable,'ColumnWidth',{col1W, col2W});
            
            set(L_nodePropsPanel, 'Sizes', [15, -1]);
            
            L_epochTagsPanel = uiextras.VBox('Parent', L_twoTables);
            
            epochTagsText = uicontrol('Parent', L_epochTagsPanel, ...
                'Style', 'text', ...
                'String', 'Epoch tags');
            
            obj.handles.epochTagsTable = uitable('Parent', L_epochTagsPanel, ...
                'Units',    'pixels', ...
                'FontSize', 12, ...
                'ColumnName', {'Property', 'Value'}, ...
                'RowName', [], ...
                'ColumnEditable', logical([0 0]), ...
                'Data', cell(5,2), ...
                'TooltipString', 'table of epoch tags for data sets');
            
            %set epoch tags table width 
            tablePos = get(obj.handles.epochTagsTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(tableWidth*.5);
            col2W = round(tableWidth*.5);
            set(obj.handles.epochTagsTable,'ColumnWidth',{col1W, col2W});
            
            set(L_epochTagsPanel, 'Sizes', [15, -1]);
            set(L_twoTables, 'Sizes', [-2, -1]);
            
            %plotter area
            L_plot = uiextras.VBox('Parent', L_right);
            
            obj.handles.plotAxes = axes('Parent', L_plot);
            
            L_plotButtons = uiextras.HButtonBox('Parent', L_plot, ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'bottom', ...
                'ButtonSize', [140, 30]);
            
            obj.handles.popFigButton = uicontrol('Parent', L_plotButtons, ...
                'Style', 'pushbutton', ...
                'String', 'Pop out fig', ...
                'Callback', @(uiobj, evt)obj.popFig);
            
            obj.handles.figToIgor = uicontrol('Parent', L_plotButtons, ...
                'Style', 'pushbutton', ...
                'String', 'Figure to Igor', ...
                'Callback', @(uiobj, evt)obj.figToIgor);
            
            obj.handles.curveFitButton = uicontrol('Parent', L_plotButtons, ...
                'Style', 'pushbutton', ...
                'String', 'Curve fit', ...
                'Callback', @(uiobj, evt)obj.openCurveFitter);
            
            obj.handles.rawDataToCommandLine = uicontrol('Parent', L_plotButtons, ...
                'Style', 'pushbutton', ...
                'String', 'Raw data to command line', ...
                'Callback', @(uiobj, evt)obj.rawDataToCommandLine);
            
            
            set(L_plot, 'Sizes', [-1, 50])
            
            set(L_right, 'Sizes', [-1 -3], 'Spacing', 10);
            
            cmenu = uicontextmenu;
            plotType1 = uimenu(cmenu, 'label', 'plotFunc1');
            plotType2 = uimenu(cmenu, 'label', 'plotFunc2');
            plotType3 = uimenu(cmenu, 'label', 'plotFunc3');
            %set(get(obj.guiTree, 'UIContainer'), 'uicontextmenu', cmenu);
            set(obj.handles.fig, 'uicontextmenu', cmenu);
            
        end
        
        function setEpochTags(obj, tagName, tagVal)
            if isscalar(str2num(tagVal))
                tagVal = str2num(tagVal);
            end
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            
            curNode = obj.analysisTree.get(curNodeIndex);
            figName = get(obj.handles.fig, 'Name');
            %4 cases: at data set level, at cell level, below data set level, above cell level
            if  isfield(curNode, 'cellName') %at data set cell level
                curCellName = curNode.cellName;
                epochIDs = [];
                treePart =  obj.analysisTree.subtree(curNodeIndex);
                leafIDs = treePart.findleaves;
                %collect all IDs
                for i=1:length(leafIDs)
                    curNode = treePart.get(leafIDs(i));
                    epochIDs = [epochIDs curNode.epochID];
                end
                obj.curCellData = loadAndSyncCellData(curCellName);
                %set tags for each epochs
                for j=1:length(epochIDs)
                    if strcmp(tagVal, 'remove')
                        set(obj.handles.fig, 'Name', 'Busy: removing tags');
                        drawnow;
                        obj.curCellData.epochs(epochIDs(j)).attributes.remove(tagName);
                    else
                        set(obj.handles.fig, 'Name', 'Busy: adding tags');
                        drawnow;
                        obj.curCellData.epochs(epochIDs(j)).attributes(tagName) = tagVal;
                    end
                end
                saveAndSyncCellData(obj.curCellData)
                
            elseif isempty(obj.analysisTree.getCellName(curNodeIndex)) && ~isfield(curNode, 'device') %above cell level
                temp = obj.analysisTree.getchildren(curNodeIndex);
                childInd = temp(1);
                curNode = obj.analysisTree.get(childInd);
                while ~isfield(curNode, 'cellName')
                    temp = obj.analysisTree.getchildren(childInd);
                    childInd = temp(1);
                    curNode = obj.analysisTree.get(childInd);
                end
                %get siglings of parent (actual cell level instead of
                %dataset level
                siblings = obj.analysisTree.getsiblings(obj.analysisTree.getparent(childInd));
                for c = 1:length(siblings);
                    dataSetNodeInd = obj.analysisTree.getchildren(siblings(c));
                    for d=1:length(dataSetNodeInd)
                        curNodeIndex = dataSetNodeInd(d);
                        cellNode = obj.analysisTree.get(curNodeIndex);
                        curCellName = cellNode.cellName;
                        epochIDs = [];
                        treePart =  obj.analysisTree.subtree(curNodeIndex);
                        leafIDs = treePart.findleaves;
                        %collect all IDs
                        for i=1:length(leafIDs)
                            curNode = treePart.get(leafIDs(i));
                            epochIDs = [epochIDs curNode.epochID];
                        end
                        obj.curCellData = loadAndSyncCellData(curCellName);
                        %set tags for each epochs
                        for j=1:length(epochIDs)
                            if strcmp(tagVal, 'remove')
                                set(obj.handles.fig, 'Name', 'Busy: removing tags');
                                drawnow;
                                obj.curCellData.epochs(epochIDs(j)).attributes.remove(tagName);
                            else
                                set(obj.handles.fig, 'Name', 'Busy: adding tags');
                                drawnow;
                                obj.curCellData.epochs(epochIDs(j)).attributes(tagName) = tagVal;
                            end
                        end
                        saveAndSyncCellData(obj.curCellData)
                    end
                end
            elseif isempty(obj.analysisTree.getCellName(curNodeIndex)) && isfield(curNode, 'device') %at cell level
                childNodes = obj.analysisTree.getchildren(curNodeIndex);
                for c=1:length(childNodes)
                    curNodeIndex = childNodes(c);
                    cellNode = obj.analysisTree.get(curNodeIndex);
                    curCellName = cellNode.cellName;
                    epochIDs = [];
                    treePart =  obj.analysisTree.subtree(curNodeIndex);
                    leafIDs = treePart.findleaves;
                    %collect all IDs
                    for i=1:length(leafIDs)
                        curNode = treePart.get(leafIDs(i));
                        epochIDs = [epochIDs curNode.epochID];
                    end
                    obj.curCellData = loadAndSyncCellData(curCellName);
                    %set tags for each epochs
                    for j=1:length(epochIDs)
                        if strcmp(tagVal, 'remove')
                            set(obj.handles.fig, 'Name', 'Busy: removing tags');
                            drawnow;
                            obj.curCellData.epochs(epochIDs(j)).attributes.remove(tagName);
                        else
                            set(obj.handles.fig, 'Name', 'Busy: adding tags');
                            drawnow;
                            obj.curCellData.epochs(epochIDs(j)).attributes(tagName) = tagVal;
                        end
                    end
                    saveAndSyncCellData(obj.curCellData)
                end
            else %below cell level
                curCellName = obj.analysisTree.getCellName(curNodeIndex);
                epochIDs = [];
                treePart =  obj.analysisTree.subtree(curNodeIndex);
                leafIDs = treePart.findleaves;
                %collect all IDs
                for i=1:length(leafIDs)
                    curNode = treePart.get(leafIDs(i));
                    epochIDs = [epochIDs curNode.epochID];
                end
                obj.curCellData = loadAndSyncCellData(curCellName);
                %set tags for each epochs
                for j=1:length(epochIDs)
                    if strcmp(tagVal, 'remove')
                        set(obj.handles.fig, 'Name', 'Busy: removing tags');
                        drawnow;
                        obj.curCellData.epochs(epochIDs(j)).attributes.remove(tagName);
                    else
                        set(obj.handles.fig, 'Name', 'Busy: adding tags');
                        drawnow;
                        obj.curCellData.epochs(epochIDs(j)).attributes(tagName) = tagVal;
                    end
                end
                saveAndSyncCellData(obj.curCellData)
            end
            set(obj.handles.fig, 'Name', figName);
            drawnow;
        end
        
        function runAnalysis(obj)
            global ANALYSIS_CODE_FOLDER
            fname = uigetfile([ANALYSIS_CODE_FOLDER filesep 'analysisTreeClasses' filesep '*.m'], 'Choose analysis function');
            commandName = strtok(fname,'.');
            
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            selectedTree = obj.analysisTree.subtree(curNodeIndex);
            eval(['T = ' commandName '(selectedTree);']);
            T = T.doAnalysis();
            TreeBrowserGUI(T);
        end
        
        function loadTree(obj)
            global ANALYSIS_FOLDER
            obj.cellDataFolder = [ANALYSIS_FOLDER 'cellData' filesep];
            obj.igorh5Folder = [ANALYSIS_FOLDER 'Igorh5' filesep];
            obj.curCellData = [];
            
            [fname, pathname] = uigetfile([ANALYSIS_FOLDER filesep 'analysisTrees' filesep '*.mat'], 'Load analysisTree');
            load(fullfile(pathname, fname)); %loads analysisTree
            
            obj.analysisTree = analysisTree;
            obj.makePlotSelectionTable();
            delete(obj.handles.fig);
            obj.buildUI();
        end
        
        function saveTree(obj)
            global ANALYSIS_FOLDER
            [fname, pathname] = uiputfile([ANALYSIS_FOLDER filesep 'analysisTrees' filesep '*.mat'], 'Save analysisTree');
            analysisTree = obj.analysisTree;
            save(fullfile(pathname, fname), 'analysisTree');
        end
        
        function addChildren(obj, nodeInd, uiTreeNode)
            
            if obj.analysisTree.isleaf(nodeInd)
                return
            end
            
            chInd = obj.analysisTree.getchildren(nodeInd);
            for i=1:length(chInd)
                nodeName = obj.analysisTree.get(chInd(i)).name;
                loc = strfind(nodeName, ':');
                if length(loc) == 2
                    nodeName = nodeName(loc(1)+1:loc(2)-1); %dataset or cell name
                elseif length(loc) == 1
                    nodeName = nodeName(loc(1)+1:end);
                end
                
                newTreeNode = uitreenode('v0', chInd(i), nodeName, obj.iconpath, obj.analysisTree.isleaf(chInd(i)));
                uiTreeNode.add(newTreeNode);
                %recursive call
                obj.addChildren(chInd(i), newTreeNode);
            end
        end
        
        function makePlotSelectionTable(obj)
            L = length(obj.analysisTree.Node);
            obj.plotSelectionTable = cell(L,3);
            for i=1:L
                if obj.analysisTree.isleaf(i) %special plot methods for leaves
                    analysisClass = obj.analysisTree.getClassName(i);
                    obj.plotSelectionTable{i,1} = ['leaf:' analysisClass];
                    obj.plotSelectionTable{i,2} = obj.leafPlotMethods;
                else
                    analysisClass = obj.analysisTree.getClassName(i);
                    if ~isempty(analysisClass)
                        obj.plotSelectionTable{i,1} = analysisClass;
                        allMethods = methods(analysisClass);
                        plotMethods = allMethods(strmatch('plot', allMethods));
                        plotMethods = plotMethods(~strcmp(plotMethods, 'plot'));
                        plotMethods = plotMethods(~strcmp(plotMethods, 'plotLeaf'));   
                        plotMethods = plotMethods(~strcmp(plotMethods, 'plotEpochData'));   
                        plotMethods = [plotMethods; obj.generalPlotMethods];
                        obj.plotSelectionTable{i,2} = plotMethods;
                    end
                end
            end
        end
        
        function resetPlotControls(obj)      
            if isfield(obj.handles, 'L_plotXY_box');
                delete(obj.handles.L_plotXY_box);
                set(obj.handles.L_plotControls, 'Sizes', [-1, 40, 40, 40]); 
            end
        end
        
        function addXYselectionToPlotControls(obj, xList, yList)    
            plotControls_children = get(obj.handles.L_plotControls, 'children');
            for i=1:length(plotControls_children)
                if ~strcmp(get(plotControls_children(i), 'Tag'), 'plotSelectionMenu');                    
                    delete(plotControls_children(i));
                end
            end
                        
            obj.handles.L_plotXY_box = uiextras.HBox('Parent', obj.handles.L_plotControls);
            
            obj.handles.plotXMenu = uicontrol('Parent', obj.handles.L_plotXY_box, ...
                'Style', 'popupmenu', ...
                'String', xList, ...
                'Units', 'normalized', ...
                'Callback', @(uiobj, evt)obj.updatePlot); %how are we going to save the selection here?
            
            vs_text = uicontrol('Parent', obj.handles.L_plotXY_box, ...
                'Style', 'text', ...
                'String', 'vs.', ...
                'Units', 'normalized'); 
            
            obj.handles.plotYMenu = uicontrol('Parent', obj.handles.L_plotXY_box, ...
                'Style', 'popupmenu', ...
                'String', yList, ...
                'Units', 'normalized', ...
                'Callback', @(uiobj, evt)obj.updatePlot); 
            
            set(obj.handles.L_plotXY_box, 'Sizes', [-1, 20, -1]);
            
            obj.handles.plotSelectionApplyAllButton = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'pushbutton', ...
                'String', 'Apply to all nodes of this type', ...
                'Callback', @(uiobj, evt)obj.applyPlotSelection);
            
            obj.handles.nodeToMatlabButton = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'pushbutton', ...
                'String', 'Node data to command line', ...
                'Callback', @(uiobj, evt)obj.nodeToMatlab);
            
            obj.handles.nodeToIgorButton = uicontrol('Parent', obj.handles.L_plotControls, ...
                'Style', 'pushbutton', ...
                'String', 'Node data to Igor', ...
                'Callback', @(uiobj, evt)obj.nodeToIgor);
            
            set(obj.handles.L_plotControls, 'Sizes', [-1, -1, 40, 40, 40]);
        end
        
        function updatePlot(obj)
            %clear previous plot
            reset(obj.handles.plotAxes);
            cla(obj.handles.plotAxes);
            
            %get everything we need to plot
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            plotClass = obj.plotSelectionTable{curNodeIndex, 1};
            if isempty(plotClass),
                return;
            end
            
            plotFuncIndex = obj.plotSelectionTable{curNodeIndex, 3} - 1; %-1 to account for 'none' option
            if plotFuncIndex == 0,
                reset(obj.handles.plotAxes);
                cla(obj.handles.plotAxes);
                obj.resetPlotControls();
                return;
            end
            plotFuncList = obj.plotSelectionTable{curNodeIndex, 2};
            plotFunc = plotFuncList{plotFuncIndex};
            curNode = obj.analysisTree.subtree(curNodeIndex);
            cellName = obj.analysisTree.getCellName(curNodeIndex);
            %load([obj.cellDataFolder cellName]);
            cellData = loadAndSyncCellData(cellName);
            obj.curCellData = cellData;
            
            %do the plot
            set(obj.handles.fig,'KeyPressFcn',[]); %get rid of callback for non SingleEpoch plots
            axes(obj.handles.plotAxes);
            %clear previous plot
            reset(obj.handles.plotAxes);
            cla(obj.handles.plotAxes);
            if strcmp(strtok(plotClass, ':'), 'leaf') %special cases for leaf nodes
                obj.resetPlotControls();
                if strcmp(plotFunc, 'plotEpochData')
                    obj.curEpochIndex = 1;
                    device = obj.analysisTree.getDevice(curNodeIndex);
                    disp(plotClass)
                    [~,plotClassTemp] = strtok(plotClass, ':');
                    plotClassTemp = plotClassTemp(2:end);
                    if ismethod(plotClassTemp, 'plotEpochData')
                        eval([plotClassTemp '.plotEpochData(curNode, cellData, device, 1);']);
                        set(obj.handles.fig,'KeyPressFcn',@(uiobj,evt)obj.keyHandler_classSpecific(evt, plotClassTemp, curNode, cellData, device, obj.curEpochIndex)); %for scrolling through epochs
                    else
                        obj.plotEpoch(curNode, cellData, device, 1);
                        set(obj.handles.fig,'KeyPressFcn',@(uiobj,evt)obj.keyHandler(evt, curNode, cellData, device, obj.curEpochIndex)); %for scrolling through epochs
                    end
                elseif strcmp(plotFunc, 'plotMeanData')
                    epochID = obj.analysisTree.get(curNodeIndex).epochID;
                    if strcmp(obj.analysisTree.getMode(curNodeIndex), 'Cell attached')
                        cellData.plotPSTH(epochID, [], obj.analysisTree.getDevice(curNodeIndex));
                        %get correct channel here
                    else
                        cellData.plotMeanData(epochID, true, [], obj.analysisTree.getDevice(curNodeIndex));
                    end
                elseif strcmp(plotFunc, 'plotSpikeRaster')
                    epochID = obj.analysisTree.get(curNodeIndex).epochID;
                    if strcmp(obj.analysisTree.getMode(curNodeIndex), 'Cell attached')
                        cellData.plotSpikeRaster(epochID, obj.analysisTree.getDevice(curNodeIndex));
                        %get correct channel here
                    else
                        %do nothing
                    end
                    
                elseif strcmp(plotFunc, 'plotLeaf')
                    [~,plotClass] = strtok(plotClass, ':');
                    plotClass = plotClass(2:end);
                    eval([plotClass '.plotLeaf(curNode, cellData);']);                
                end
            else %not leaf
                curNodeData = curNode.get(1);
                if strcmp(plotFunc, 'XYplotter_epochParams') %special cases for generalized plotters
                    if isfield(curNodeData, 'stimParameterList')
                        xList = curNodeData.stimParameterList;
                    else
                        xList = [];
                    end
                    if isfield(curNodeData, 'byEpochParamList')
                        yList = curNodeData.byEpochParamList;
                    else
                        yList = [];
                    end
                    if ~isfield(obj.handles, 'L_plotXY_box') || ~ishandle(obj.handles.L_plotXY_box)
                        obj.addXYselectionToPlotControls(xList, yList);
                    end
                    if ~isequal(yList', get(obj.handles.plotYMenu, 'String'))
                        disp('remaking menu'); 
                        obj.addXYselectionToPlotControls(xList, yList);
                    end
                    %make the plot    
                    xName = xList{get(obj.handles.plotXMenu, 'Value')};
                    yName = yList{get(obj.handles.plotYMenu, 'Value')};
                    xvals = curNodeData.(xName);
                    yField = curNodeData.(yName);
                    if strcmp(yField.units, 's') %if a time, take the median
                        yvals = yField.median_c;
                    else
                        yvals = yField.mean_c;
                    end
                    errs = yField.SEM;
                    errorbar(xvals, yvals, errs);
                    xlabel(xName);
                    ylabel([yName ' (' yField(1).units ')' ]);
                    obj.printCodeForPlotterFunction_byEpoch(xName,yName);
                elseif strcmp(plotFunc, 'XYplotter_singleValParams')
                    if isfield(curNodeData, 'stimParameterList')
                        xList = curNodeData.stimParameterList;
                    else
                        xList = [];
                    end
                    if isfield(curNodeData, 'singleValParamList')
                        yList = curNodeData.singleValParamList;
                    else
                        yList = [];
                    end
                    if ~isfield(obj.handles, 'L_plotXY_box') || ~ishandle(obj.handles.L_plotXY_box)
                        obj.addXYselectionToPlotControls(xList, yList);
                    end
                    if ~isequal(yList', get(obj.handles.plotYMenu, 'String'))
                        disp('remaking menu'); 
                        obj.addXYselectionToPlotControls(xList, yList);
                    end
                    %make the plot
                    xName = xList{get(obj.handles.plotXMenu, 'Value')};
                    yName = yList{get(obj.handles.plotYMenu, 'Value')};
                    xvals = curNodeData.(xName);
                    yField = curNodeData.(yName);
                    
                    yvals = yField.value;
                    plot(xvals, yvals, 'bx-');
                    xlabel(xName);
                    ylabel([yName ' (' yField(1).units ')' ]);
                    obj.printCodeForPlotterFunction_singleVal(xName,yName);
                else
                    obj.resetPlotControls();
                    eval([plotClass '.' plotFunc '(curNode, cellData);']);
                    
                end
            end
        end
        
        function printCodeForPlotterFunction_singleVal(obj, xName, yName)
           disp('%%%%%%%%%%%%%% plotter code %%%%%%%%%%%%%%'); 
           disp(['function plot_' xName 'Vs' yName '(node, cellData)']);
           disp('rootData = node.get(1);');
           disp(['xvals = rootData.' xName ';']);
           disp(['yField = rootData.' yName ';']);
           disp('yvals = yField.value;');
           disp(['plot(xvals, yvals, ''' 'bx-' ''');']);
           disp(['xlabel(''' xName ''');']);
           disp(['ylabel([''' yName ' (' ''' yField.units ''' ')''' ']);']);
           disp('end');
           disp('%%%%%%%%%%%%%% plotter code %%%%%%%%%%%%%%'); 
        end
        
        function printCodeForPlotterFunction_byEpoch(obj, xName, yName)
           disp('%%%%%%%%%%%%%% plotter code %%%%%%%%%%%%%%'); 
           disp(['function plot_' xName 'Vs' yName '(node, cellData)']);
           disp('rootData = node.get(1);');
           disp(['xvals = rootData.' xName ';']);
           disp(['yField = rootData.' yName ';']);
           disp('if strcmp(yField.units, ''s'')');
           disp('yvals = yField.median_c;');
           disp('else');
           disp('yvals = yField.mean_c;');
           disp('end');
           disp('errs = yField.SEM;');
           disp('errorbar(xvals, yvals, errs);');
           disp(['xlabel(''' xName ''');']);
           disp(['ylabel([''' yName ' (' ''' yField.units ''' ')''' ']);']);
           disp('end');
           disp('%%%%%%%%%%%%%% plotter code %%%%%%%%%%%%%%'); 
        end
        
        function onPlotSelectionMenu(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            obj.plotSelectionTable{curNodeIndex, 3} = get(obj.handles.plotSelectionMenu, 'Value');
            obj.updatePlot();
        end
        
        function onNodeSelected(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            if ~isempty(obj.plotSelectionTable{curNodeIndex, 2})
                set(obj.handles.plotSelectionMenu, 'String', ['none'; obj.plotSelectionTable{curNodeIndex, 2}]);
                if isempty(obj.plotSelectionTable{curNodeIndex, 3})
                    set(obj.handles.plotSelectionMenu, 'Value', 2);
                    obj.plotSelectionTable{curNodeIndex, 3} = 2;
                else
                    set(obj.handles.plotSelectionMenu, 'Value', obj.plotSelectionTable{curNodeIndex, 3});
                end
            end
            
            obj.populateEpochTagsTable();
            obj.populateNodePropertiesTable();
            obj.updatePlot();
        end
        
        function populateNodePropertiesTable(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            curNodeData = obj.analysisTree.get(curNodeIndex);
            allFields = fieldnames(curNodeData);
            
            L = length(allFields);
            D = cell(L,2);
            z=1;
            for i=1:L
                %D{i,1} = allFields{i};
                if isstruct(curNodeData.(allFields{i}))
                    %do nothing, don't add struct
                    %D{i,2} = '<struct>';
                elseif iscell(curNodeData.(allFields{i}))
                    D{z,2} = '<cellArray>';
                else
                    D{z,1} = allFields{i};
                    sizeVal = size(curNodeData.(allFields{i}));
                    if sizeVal(1) > 1 && sizeVal(2) > 1
                        D{z,2} = '<array>';
                    else
                        D{z,2} = num2str(curNodeData.(allFields{i}));
                    end
                    z=z+1;
                end
            end
            set(obj.handles.nodePropertiesTable, 'data', D)
        end
        
        function populateEpochTagsTable(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            curNodeData = obj.analysisTree.get(curNodeIndex);            
            curCellName = obj.analysisTree.getCellName(curNodeIndex);
            if isfield(obj.curCellData, 'savedFileName') && strcmp(obj.curCellData.savedFileName, curCellName) %cellData already loaded
                 %do nothing
            else %load it
                obj.curCellData = loadAndSyncCellData(curCellName);
            end
            D = cell(5,2);
            if isfield(curNodeData, 'class') %only display for level of data sets
                %get all epochsIDs under this node
                treePart =  obj.analysisTree.subtree(curNodeIndex);
                leafIDs = treePart.findleaves;
                %collect all IDs
                epochIDs = [];
                for i=1:length(leafIDs)
                    curNode = treePart.get(leafIDs(i));
                    epochIDs = [epochIDs curNode.epochID];
                end
                %look for each tags
                allTags = obj.epochTags.keys;
                z = 1;
                for i=1:length(allTags)
                   curVals = getEpochVals(obj.curCellData, allTags{i}, epochIDs);
                   if iscell(curVals)
                       curVals = curVals(~isnan_cell(curVals));                       
                   else
                       curVals = curVals(~isnan(curVals));
                   end
                   curVals = unique(curVals);
                   if iscell(curVals)
                       curVals = cell2mat(curVals);
                   end
                   
                   if ~isempty(curVals)
                       D{z,1} = allTags{i};
                       D{z,2} = num2str(curVals);
                       z=z+1;
                   end
                end
                
                %vals = getEpochVals(obj, paramName, epochInd)
            end
            set(obj.handles.epochTagsTable, 'data', D)
        end
        
        
        function resizeWindow(obj)
            if isfield(obj.handles, 'fig')
                figurePos = get(obj.handles.fig, 'Position');
                width = figurePos(3);
                height = figurePos(4);
                set(obj.guiTree, 'Position', [0.02*width 0.02*height, 0.38*width 0.96*height]);
            end
            
            if isfield(obj.handles, 'nodePropertiesTable')
                tablePos = get(obj.handles.nodePropertiesTable,'Position');
                tableWidth = tablePos(3);
                col1W = round(tableWidth*.5);
                col2W = round(tableWidth*.5);
                set(obj.handles.nodePropertiesTable,'ColumnWidth',{col1W, col2W});
            end
        end
        
        function plotEpoch(obj, curNode, cellData, device, epochIndex)
            axes(obj.handles.plotAxes);
            nodeData = curNode.get(1);
            cellData.epochs(nodeData.epochID(epochIndex)).plotData(device);
            title(['Epoch # ' num2str(nodeData.epochID(epochIndex)) ': ' num2str(epochIndex) ' of ' num2str(length(nodeData.epochID))]);
            if strcmp(device, 'Amplifier_Ch1')
                spikesField = 'spikes_ch1';
            else
                spikesField = 'spikes_ch2';
            end
            spikeTimes = cellData.epochs(nodeData.epochID(epochIndex)).get(spikesField);
            if ~isnan(spikeTimes)
                [data, xvals] = cellData.epochs(nodeData.epochID(epochIndex)).getData(device);
                hold('on');
                plot(xvals(spikeTimes), data(spikeTimes), 'rx');
                hold('off');
            end
        end
        
        function applyPlotSelection(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            v = get(obj.handles.plotSelectionMenu, 'Value');
            L = size(obj.plotSelectionTable, 1);
            for i=1:L
                if strcmp(obj.plotSelectionTable{i,1}, obj.plotSelectionTable{curNodeIndex,1}) %%same class
                    obj.plotSelectionTable{i,3} = v;
                end
            end
        end
        
        function nodeToIgor(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            nodeData = obj.analysisTree.get(curNodeIndex);
            
            [fname,pathname] = uiputfile('*.h5', 'Specify hdf5 export file for Igor', obj.igorh5Folder);
            if ~isempty(fname)
                datasetName = inputdlg('Enter dataset name', 'Dataset name');
                if ~isempty(datasetName)
                    datasetName = datasetName{1}; %inputdlg returns a cell array instead of a string
                    exportStructToHDF5(nodeData, fullfile(pathname, fname), datasetName);
                end
            end
        end
        
        function popFig(obj)
            h = figure;
            copyobj(obj.handles.plotAxes,h);
        end
        
        function figToIgor(obj)
            makeAxisStruct(obj.handles.plotAxes, obj.igorh5Folder);
        end
        
        function openCurveFitter(obj)
            chInd = get(obj.handles.plotAxes, 'children');            
            %fit only first child for now
            if length(chInd) > 1
                chInd = chInd(1);
            end
            xvals = get(chInd, 'xdata');
            yvals = get(chInd, 'ydata');
            if isprop(chInd, 'udata') %if has errors
                errvals = get(chInd, 'udata');
                zeroInd = find(errvals==0);
                if ~isempty(zeroInd)
                    errvals(zeroInd) = min(errvals) / 2; %set zeros to half min                    
                end
                weights = 1./errvals;
                cftool(xvals,yvals,[],weights);
            else
                cftool(xvals,yvals);
            end            
        end
        
        function rawDataToCommandLine(obj)
            %TODO: deal with cell-attached data differently here, return
            %PSTH and cell array of spike times
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            nodeData = obj.analysisTree.get(curNodeIndex);
            mode = getMode(obj.analysisTree, curNodeIndex);
            device = getDevice(obj.analysisTree, curNodeIndex);
            if strcmp(mode, 'Cell attached')
                [PSTH, timeAxis_PSTH] = obj.curCellData.getPSTH(nodeData.epochID, [], device);
                L = length(nodeData.epochID);
                spikeTimes = cell(L,1);
                for i=1:L
                    [spikeTimes{i}, timeAxis_spikes] = obj.curCellData.epochs(nodeData.epochID(i)).getSpikes(device);
                end
                assignin('base', 'PSTH', PSTH);
                assignin('base', 'timeAxis_spikes', timeAxis_spikes);
                assignin('base', 'timeAxis_PSTH', timeAxis_PSTH);
                assignin('base', 'spikeTimes', spikeTimes);
            else
                [meanData, timeAxis] = obj.curCellData.getMeanData(nodeData.epochID, device);
                L = length(nodeData.epochID);
                dataMatrix = zeros(L, length(meanData));
                for i=1:L
                    dataMatrix(i,:) = obj.curCellData.epochs(nodeData.epochID(i)).getData(device)';
                end
                assignin('base', 'meanData', meanData);
                assignin('base', 'timeAxis', timeAxis);
                assignin('base', 'dataMatrix', dataMatrix);
            end
        end
        
        function nodeToMatlab(obj)
            selectedNodes = get(obj.guiTree, 'selectedNodes');
            curNodeIndex = get(selectedNodes(1), 'Value');
            nodeData = obj.analysisTree.get(curNodeIndex);
            assignin('base', 'nodeData', nodeData);
        end
        
        function keyHandler(obj, evt, curNode, cellData, device, epochIndex) %takes control of the epochIndex
            nodeData = curNode.get(1);
            epochIndex = obj.curEpochIndex;
            switch evt.Key
                case 'leftarrow'
                    obj.curEpochIndex = max(epochIndex-1, 1);
                    obj.plotEpoch(curNode, cellData, device, obj.curEpochIndex);
                case 'rightarrow'
                    obj.curEpochIndex = min(epochIndex+1, length(nodeData.epochID));
                    obj.plotEpoch(curNode, cellData, device, obj.curEpochIndex);
            end
        end
        
        function keyHandler_classSpecific(obj, evt, plotClass, curNode, cellData, device, epochIndex) %takes control of the epochIndex
            nodeData = curNode.get(1);
            epochIndex = obj.curEpochIndex;
            switch evt.Key
                case 'leftarrow'
                    obj.curEpochIndex = max(epochIndex-1, 1);
                    eval([plotClass '.plotEpochData(curNode, cellData, device,' num2str(obj.curEpochIndex) ');']);
                case 'rightarrow'
                    obj.curEpochIndex = min(epochIndex+1, length(nodeData.epochID));
                    eval([plotClass '.plotEpochData(curNode, cellData, device,' num2str(obj.curEpochIndex) ');']);
            end
        end
        
    end
    
end

