classdef CellComparisonPlotter_basic < CellComparisonPlotter
    properties
        plotAxes
        variableNames
    end
    
    
    methods
        
        function obj = CellComparisonPlotter_basic(comparisonBrowser)
            plotMode = 'basic';
            obj = obj@CellComparisonPlotter(comparisonBrowser, plotMode);
        end
        
        function drawOptionsMenu(obj)
            validCols = logical(obj.getValidColumns());
            obj.variableNames = obj.comparisonBrowser.dtab.Properties.VariableNames(validCols);
            
            obj.handles.variableChoiceList1 = uicontrol('Style','listbox',...
                'Parent', obj.handles.menuArea, ...
                'FontSize', 12,...
                'String', obj.variableNames);
            
            obj.handles.variableChoiceList2 = uicontrol('Style','listbox',...
                'Parent', obj.handles.menuArea, ...
                'FontSize', 12,...
                'String', horzcat('none', obj.variableNames));
                                 
            obj.handles.updatePlotButton = uicontrol('Style', 'pushbutton', ...
                'Parent', obj.handles.menuArea, ...
                'String', 'Update plot', ...
                'Callback', @(uiobj, evt) obj.drawPlot());
        end
        
        function drawPlot(obj)
            if ~obj.plotInitialized
                ax = axes('Parent', obj.handles.plotArea);
                obj.plotAxes = ax;
            else
                ax = obj.plotAxes;
                cla(ax);
                
            end
           
            obj.handles.dataPlotLineHandles = zeros(obj.comparisonBrowser.numCells,1);

            % what variables to use?
            numDims = 1;
            varIndex1 = get(obj.handles.variableChoiceList1, 'Value');
            var1 = obj.variableNames(varIndex1);
            
            varIndex2 = get(obj.handles.variableChoiceList2, 'Value');
            if varIndex2 > 1
                var2 = obj.variableNames(varIndex2 - 1);
                numDims = 2;
            else
                var2 = '';
            end
            
            for ci = 1:obj.comparisonBrowser.numCells
                xval = obj.comparisonBrowser.dtab{ci, var1};
                if numDims == 2
                    yval = obj.comparisonBrowser.dtab{ci, var2};
                    lineHandle = plot(ax, xval, yval, '.', 'MarkerFaceColor', 'k', 'ButtonDownFcn', {@obj.cellPlotSelect, ci});
                    
                else
                    lineHandle = line(ax, [xval, xval], [-.5, .5], 'Color', 'k', 'ButtonDownFcn', {@obj.cellPlotSelect, ci});
                end
                obj.handles.dataPlotLineHandles(ci) = lineHandle;
                hold(ax, 'on')

            end
            hold(ax, 'off');
            xlabel(ax, var1, 'Interpreter', 'none');
            if numDims == 2
                ylabel(ax, var2, 'Interpreter', 'none');
            end

            obj.plotInitialized = true;
            
            obj.updateCellSets();
            obj.updateSelection();
            
        end
        
        function cellPlotSelect(obj, ~, ~, ci)
            fprintf('%s: %s %g\n', obj.comparisonBrowser.dtab.cellType{ci}, obj.comparisonBrowser.dtab.Properties.RowNames{ci}, ci);
            obj.comparisonBrowser.updateSelectedCells(ci)
        end        
        
        function updateCellSets(obj)
            if ~obj.plotInitialized
                return
            end
            lineHandles = obj.handles.dataPlotLineHandles;
            setsByCell = obj.comparisonBrowser.getSetsByCell();
            for ci = 1:obj.comparisonBrowser.numCells
                if lineHandles(ci) > 0
                    if setsByCell(ci) == 0
                        set(lineHandles(ci), 'Visible', 'off');
                    else
                        set(lineHandles(ci), 'Visible', 'on');
                        set(lineHandles(ci), 'Color', obj.comparisonBrowser.colors(setsByCell(ci), :));
                    end
                end
            end
        end
        
        function updateSelection(obj)
            if ~obj.plotInitialized
                return
            end            
            % set width of lines by selection state
            for ci = 1:obj.comparisonBrowser.numCells
                state = obj.comparisonBrowser.currentSelection(ci);
                switch state
                    case 0
                        wid = 20;
                    case 1
                        wid = 35;
                    case 2
                        wid = 45;
                end
                lineHandles = obj.handles.dataPlotLineHandles;
                if lineHandles(ci) > 0
                    set(lineHandles(ci), 'MarkerSize', wid);
                    set(lineHandles(ci), 'LineWidth', wid/10);
                end
            end            
        end
        
        function cols = getValidColumns(obj)
            % run through dtab columns and check that they are 'single' 'type'
            numCols = size(obj.comparisonBrowser.dtab, 2);
            cols = zeros(numCols,1);
            for coli = 1:numCols
                colName = obj.comparisonBrowser.dtab.Properties.VariableNames{coli};
                ty = obj.comparisonBrowser.dtabColumns{colName, 'type'};
                cols(coli) = strcmp(ty, 'single');
            end
        end
    end
    
    
end