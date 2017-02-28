classdef CellComparisonPlotter < handle
    
    properties
        plotMode
        comparisonBrowser
        handles
        plotInitialized = false;
        settings
    end
    
    properties (Constant)
        plotModeOptions = {'basic','histogram','vectors','PSTH'}
    end
    
    methods
        function obj = CellComparisonPlotter(comparisonBrowser, plotMode)
            obj.comparisonBrowser = comparisonBrowser;
            obj.plotMode = plotMode;
            obj.settings = struct();
            
            obj.initializeGui();
            obj.drawOptionsMenu();
            obj.updateCellSets();
            obj.updateSelection();
        end
        
        function initializeGui(obj)
            obj.handles = struct();
            
            obj.handles.mainFigure = figure( ...
            'Name',         ['Plotter' obj.plotMode], ...
            'NumberTitle',  'off', ...
            'ToolBar',      'none',...
            'Menubar',      'none');
        
            obj.handles.mainPanel = uiextras.HBoxFlex('Parent', obj.handles.mainFigure);
        
            obj.handles.menuArea = uiextras.VBox('Parent', obj.handles.mainPanel);
            
            obj.handles.plotArea = uiextras.VBox('Parent', obj.handles.mainPanel);
            
            set(obj.handles.mainPanel, 'Sizes', [200, -1])
            
        end

    end
       
    methods  (Abstract)
        
        drawOptionsMenu(obj)
        
        drawPlot(obj)
        
        updateCellSets(obj)
        
        updateSelection(obj)
       
    end
    
    
end