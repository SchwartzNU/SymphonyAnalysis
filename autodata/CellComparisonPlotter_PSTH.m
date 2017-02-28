classdef CellComparisonPlotter_PSTH < CellComparisonPlotter
    properties
        
        
    end
    
    
    methods
        
        function obj = CellComparisonPlotter_PSTH(comparisonBrowser)
            plotMode = 'PSTH';
            obj = obj@CellComparisonPlotter(comparisonBrowser, plotMode);
        end
        
        function drawOptionsMenu(obj)
                                 
            obj.handles.updatePlotButton = uicontrol('Style', 'pushbutton', ...
                'Parent', obj.handles.menuArea, ...
                'String', 'Update plot', ...
                'Callback', @(uiobj, evt) obj.drawPlot());
        end
        
        function drawPlot(obj)
            global CELL_DATA_FOLDER
            ax = axes('Parent', obj.handles.plotArea);
            if obj.plotInitialized
                cla(ax);
            end
            obj.handles.dataPlotLineHandles = zeros(obj.comparisonBrowser.numCells,1);

            for ci = 1:obj.comparisonBrowser.numCells

                bestSize = obj.comparisonBrowser.dtab{ci, 'SMS_offSpikes_prefSize'};
                if isnan(bestSize)
                    continue
                end

                dataSet = obj.comparisonBrowser.dtab{ci, 'SMS_sp_dataset'}{1};
                load([CELL_DATA_FOLDER obj.comparisonBrowser.cellNames{ci}])
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
                lineHandle = plot(ax, xvals, spCount, 'ButtonDownFcn', {@obj.cellPlotSelect, ci});
                obj.handles.dataPlotLineHandles(ci) = lineHandle;
                hold(ax, 'on')

            end
            hold(ax, 'off');
            xlim(ax, [0,2.5])
            obj.plotInitialized = true;
            
        end
        
        function cellPlotSelect(obj, ~, ~, ci)
            fprintf('%s: %s %g\n', obj.comparisonBrowser.dtab.cellType{ci}, obj.comparisonBrowser.dtab.Properties.RowNames{ci}, ci);
            obj.comparisonBrowser.updateSelectedCells(ci)
        end        
        
        function updateCellSets(obj)
%             lineHandles = obj.handles.dataPlotLineHandles{fi};
%             for ci = 1:length(obj.cellNames)
%                 if lineHandles(ci) > 0
% 
%         if ~isempty(thisCellsSet)
%             set(lineHandles(ci), 'Color', obj.colors(thisCellsSet,:));
%         end
%                 end
%             end            
        end
        
        function updateSelection(obj)
            % set width of lines by selection state
%             for ci = 1:length(obj.cellNames)
%                 state = obj.currentSelection(ci);
%                 switch state
%                     case 0
%                         wid = 1;
%                     case 1
%                         wid = 3;
%                     case 2
%                         wid = 4;
%                 end
%                 for fi = 1:length(obj.handles.dataPlotAxisHandles)
%                     lineHandles = obj.handles.dataPlotLineHandles{fi};
%                     if lineHandles(ci) > 0
%                         set(lineHandles(ci), 'LineWidth', wid);
%                     end
%                 end
%             end            
        end
        
    end
    
    
end