classdef ColorIsoResponseFigure < handle

    properties
        deviceName
        epochIndex
        spikeThreshold
        spikeDetectorMode
        spikeDetector
        analysisRegion
        devices

        baseIntensity1
        baseIntensity2
        stimulusInfo
        colorNames
%         stimulusModes = {'default','ramp'};
        
        plotRange1
        plotRange2
        ignoreNextEpoch = false;
        runPausedSoMayNeedNullEpoch = true;
        protocolShouldStop = false;
           
        epochData
        
        pointData
        interpolant = [];
        modelCoefs
        
        isoPlotClickMode = 'select'
        isoPlotClickCountRemaining = 0;
        isoPlotClickHistory = [];
        selectedPoint = [];
        
        handles
        figureHandle
        selectedVariable
        variables
    end
    
    properties (Dependent)
        contrastRange1
        contrastRange2
    end

    
    methods
        
        function obj = ColorIsoResponseFigure(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParameter('colorNames',{'',''});
            ip.addParameter('baseIntensity1', .1);
            ip.addParameter('baseIntensity2', .1);
            ip.addParameter('variable', '');
            ip.addParameter('epochData', {});
            
            ip.parse(varargin{:});
            
            obj.epochIndex = 0;
            obj.baseIntensity1 = ip.Results.baseIntensity1;
            obj.baseIntensity2 = ip.Results.baseIntensity2;
            obj.colorNames = ip.Results.colorNames;
            obj.selectedVariable = ip.Results.variable;
            obj.epochData = ip.Results.epochData;
            
            obj.plotRange1 = obj.contrastRange1;
            obj.plotRange2 = obj.contrastRange2;
                       
%             obj.resetPlots();
            obj.createUi();
            obj.analyzeData();
            obj.updateUi();
        end
        
        
        function createUi(obj)
            
            import appbox.*;
            obj.figureHandle = figure();
            
            set(obj.figureHandle, 'MenuBar', 'none');
            set(obj.figureHandle, 'NumberTitle', 'off');
            set(obj.figureHandle, 'GraphicsSmoothing', 'on');
            set(obj.figureHandle, 'DefaultAxesFontSize',8, 'DefaultTextFontSize',8);
            
            obj.handles.figureBox = uix.HBoxFlex('Parent', obj.figureHandle, 'Spacing',10);
            
            obj.handles.measurementDataBox = uix.VBoxFlex('Parent', obj.handles.figureBox, 'Spacing', 10);
            
            obj.handles.variableSelection = uicontrol('Parent', obj.handles.measurementDataBox, ...
                                    'Style','popupmenu', ...
                                    'String',{'',''}, ...
                                    'Callback', @obj.selectVariable);

            obj.handles.dataTable = uitable('Parent', obj.handles.measurementDataBox, ...
                                    'ColumnName', {'contr 1', 'contr 2', 'mean', 'VMR', 'rep'}, ...
                                    'ColumnWidth', {60, 60, 40, 40, 40}, ...
                                    'CellSelectionCallback', @obj.dataTableSelect);
            obj.handles.singlePointTable = uitable('Parent', obj.handles.measurementDataBox, ...
                                    'ColumnName', {'index', 'response'}, ...
                                    'ColumnWidth', {60, 60}, ...
                                    'CellSelectionCallback', @obj.singlePointTableSelect);
            obj.handles.displayMeanResponseCheckbox = uicontrol('Style', 'checkbox', ...
                        'Value', true, ...
                        'String', 'Mean response',...
                        'Parent', obj.handles.measurementDataBox);
            obj.handles.epochSelectionAxes = axes('Parent', obj.handles.measurementDataBox);
            obj.handles.measurementDataBox.Heights = [30, -2, -.5, 20, -1];
            
            obj.handles.isoDataBox = uix.VBox('Parent', obj.handles.figureBox, 'Spacing', 10);
            obj.handles.dataDisplayText = uicontrol('Parent',obj.handles.isoDataBox,...
                                    'Style','text', 'String', '','FontSize',14);
            obj.handles.isoAxes = axes('Parent', obj.handles.isoDataBox);
            obj.handles.isoDataBox.Heights = [20,-1];
            
            
            obj.handles.modelBox = uix.VBox('Parent', obj.handles.figureBox);
            uicontrol('Style', 'pushbutton', ...
                'String', 'Export for model',...
                'Parent', obj.handles.modelBox,...
                'Callback', @(a,b) obj.exportDataForModel());
                    
            obj.handles.figureBox.Widths = [300, -1, 30];
        end
        
        
        function analyzeData(obj)
            % collect all the epochs into a response table
            responseData = [];
            
            % get the data variable names
            e = obj.epochData{1};
            p = e.parameters;
            
            try
                if isKey(p, 'annulusMode')
                    dataSetName = sprintf('Diam: %g Voltage: %g Annulus: %g NDF: %g GreenLED: %g uvLED: %g', p('spotDiameter'),p('ampHoldSignal'),p('annulusMode'),p('NDF'),p('greenLED'),p('uvLED'));
                else
                    dataSetName = sprintf('Diam: %g Voltage: %g Annulus: 0 NDF: %g GreenLED: %g uvLED: %g', p('spotDiameter'),p('ampHoldSignal'),p('NDF'),p('greenLED'),p('uvLED'));
                end
                set(obj.figureHandle, 'Name', dataSetName);
            end
            
            vars = fieldnames(e.response);
            obj.variables = {'Select variable'};
            for i = 1:length(vars)
                if isnumeric(e.response.(vars{i}))
                    obj.variables{end+1,1} = vars{i};
                end
            end
            obj.handles.variableSelection.String = obj.variables;
            
            for ei = 1:length(obj.epochData)
                e = obj.epochData{ei};
                if e.ignore
                    continue
                end
                
                responseData(end+1,:) = [e.parameters('contrast1'), e.parameters('contrast2'), e.response.(obj.selectedVariable)];
            end

            % combine responses into points
            [points, ~, indices] = unique(responseData(:,[1,2]), 'rows');
            for i = 1:size(points,1)
                m = mean(responseData(indices == i, 3));
                v = var(responseData(indices == i, 3));
                obj.pointData(i,:) = [points(i,1), points(i,2), m, v/abs(m), sum(indices == i)];
            end
            
            % calculate map of current results
            if size(obj.pointData, 1) >= 3
                c1 = obj.pointData(:,1);
                c2 = obj.pointData(:,2);
                r = obj.pointData(:,3);
                obj.interpolant = scatteredInterpolant(c1, c2, r, 'linear', 'none');
            end
            
            % calculate extents of display plot (though we can't actually go outside the range once calculated)
            obj.plotRange1 = [min([min(obj.pointData(:,1)), obj.contrastRange1(1)]), max([max(obj.pointData(:,1)), obj.contrastRange1(2)])];
            obj.plotRange2 = [min([min(obj.pointData(:,2)), obj.contrastRange2(1)]), max([max(obj.pointData(:,2)), obj.contrastRange2(2)])];
        
        
            disp('before check')
            % fit the pointdata to a simple model
            if size(obj.pointData,1) > 3
                disp('fitting model')
                model = fitlm(obj.pointData(:,1:2), obj.pointData(:,3),'linear','RobustOpts','off');
                obj.modelCoefs = horzcat(model.Coefficients.Estimate, model.Coefficients.pValue);
            else
                obj.modelCoefs = [];
            end        
        
        end
        
        function selectVariable(obj, menu, ~)
            newVar = menu.String{menu.Value};
            obj.selectedVariable = newVar;
            obj.analyzeData();
            obj.updateUi();
        end
        
        function exportDataForModel(obj, ~, ~)
            
            fprintf('export data to %s', pwd)
            
            % 
            response = [];
            stimulus = [];
            
            for ei = 1:length(obj.epochData)
                e = obj.epochData{ei};
                if e.ignore
                    continue
                end
                
                r = e.signal;
                response = horzcat(response, r');
                
                % generate spot flash
%                 t = e.t;
                t = (1/100:1/100:max(e.t)) - 1/100;

                startTime = e.parameters('preTime') / 1000;
                endTime = e.parameters('stimTime') / 1000 + startTime;
                
                on = t > startTime & t <= endTime;
%                 stim = vertcat(e.parameters('intensity1') * on + e.parameters('baseIntensity1') * ~on, e.parameters('intensity2') * on + e.parameters('baseIntensity2') * ~on);
                stim = vertcat(e.parameters('contrast1') * on, e.parameters('contrast2') * on);
                stimulus = horzcat(stimulus, stim);
            end                
            epochData = obj.epochData;
            whos stimulus
            whos response
            save('colorIsoExportedForModel','response','stimulus', 'epochData');
            
        end
        
        
        function updateUi(obj)
            
            % update point data table
            obj.handles.dataTable.Data = obj.pointData;
            
            % update selected point epochs table
            if ~isempty(obj.selectedPoint)
                point = obj.selectedPoint(1,:);
                pointTable = [];
                for ei = 1:length(obj.epochData)
                    e = obj.epochData{ei};
                    if e.ignore
                        continue
                    end
                    if point(1) == e.parameters('contrast1') && point(2) == e.parameters('contrast2')
                        pointTable(end+1,:) = [ei, e.response.(obj.selectedVariable)];
                    end
                end
                obj.handles.singlePointTable.Data = pointTable;
            end
            
            
            % update iso data plot
            cla(obj.handles.isoAxes);
            hold(obj.handles.isoAxes, 'on');

            if ~isempty(obj.pointData)
                if ~isempty(obj.interpolant)
                    try
                        c1p = linspace(min(obj.pointData(:,1)), max(obj.pointData(:,1)), 20);
                        c2p = linspace(min(obj.pointData(:,2)), max(obj.pointData(:,2)), 20);
                        [C1p, C2p] = meshgrid(c1p, c2p);
                        int = obj.interpolant(C1p, C2p);
%                         f = fspecial('average');
%                         int = imfilter(int, f);
                        s = pcolor(obj.handles.isoAxes, C1p, C2p, int);
                        shading(obj.handles.isoAxes, 'interp');
                        set(s, 'PickableParts', 'none');
                        
                        if abs(max(int(:)) - min(int(:))) > 0
                            contour(obj.handles.isoAxes, C1p, C2p, int, 'k', 'ShowText','on', 'PickableParts', 'none')
                        end
                    end
                end

                % observations
                for oi = 1:size(obj.pointData,1)
                    if ~isempty(obj.selectedPoint) && all([obj.pointData(oi,1), obj.pointData(oi,2)] == obj.selectedPoint(1,:))
                        siz = 90;
                        edg = 'w';
                    else
                        siz = 40;
                        edg = 'k';
                    end
                    scatter(obj.handles.isoAxes, obj.pointData(oi,1), obj.pointData(oi,2), siz, 'CData', obj.pointData(oi,3), ...
                        'LineWidth', 1, 'MarkerEdgeColor', edg, 'MarkerFaceColor', 'flat', 'ButtonDownFcn', {@obj.isoPlotPointClick, oi})
                end
            end
            
            % plot click points
            if ~isempty(obj.isoPlotClickHistory)
                scatter(obj.handles.isoAxes, obj.isoPlotClickHistory(:,1), obj.isoPlotClickHistory(:,2), '+', ...
                    'LineWidth', 2, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'flat')
            end
            
            
            % draw some nice on/off divider lines, and contrast boundary lines
%             line(obj.handles.isoAxes, [0,0], obj.plotRange2, 'LineStyle', ':', 'Color', 'k', 'PickableParts', 'none');
%             line(obj.handles.isoAxes, obj.plotRange1, [0,0], 'LineStyle', ':', 'Color', 'k', 'PickableParts', 'none');
%             rectangle(obj.handles.isoAxes, 'Position', [-1, -1, diff(obj.contrastRange1), diff(obj.contrastRange2)], 'EdgeColor', 'k', 'LineWidth', 1, 'PickableParts', 'none');
%             
%             xlabel(obj.handles.isoAxes, obj.colorNames{1});
%             ylabel(obj.handles.isoAxes, obj.colorNames{2});
%             xlim(obj.handles.isoAxes, obj.plotRange1 + [-.1, .1]);
%             ylim(obj.handles.isoAxes, obj.plotRange2 + [-.1, .1]);
%             set(obj.handles.isoAxes,'LooseInset',get(obj.handles.isoAxes,'TightInset'))
%             hold(obj.handles.isoAxes, 'off');
            
            % Update selected epoch in epoch signal display and table
            if ~isempty(obj.selectedPoint)
                cla(obj.handles.epochSelectionAxes);
                point = obj.selectedPoint(1,:);
                
                if ~obj.handles.displayMeanResponseCheckbox.Value

                    for ei = 1:length(obj.epochData)
                        e = obj.epochData{ei};
                        if all([e.parameters('contrast1'), e.parameters('contrast2')] == point)
                            if e.ignore
                                continue
                            end                            
                            signal = e.signal;
                            signal = signal - median(signal(1:1000));
                            hold(obj.handles.epochSelectionAxes, 'on')
                            plot(obj.handles.epochSelectionAxes, e.t, signal);
                            plot(obj.handles.epochSelectionAxes, e.spikeTimes, signal(e.spikeFrames), '.');
                            hold(obj.handles.epochSelectionAxes, 'off')
                        end
                    end
                else
                    signals = [];
                    for ei = 1:length(obj.epochData)
                        e = obj.epochData{ei};
                        if all([e.parameters('contrast1'), e.parameters('contrast2')] == point) 
                            if e.ignore
                                continue
                            end
                            signal = e.signal;
                            signal = signal - median(signal(1:1000));
                            signals(end+1,:) = signal;
                        end
                    end
                    signal = mean(signals, 1);
                    hold(obj.handles.epochSelectionAxes, 'on')
                    plot(obj.handles.epochSelectionAxes, e.t, signal);
                    hold(obj.handles.epochSelectionAxes, 'off')     
                end
                set(obj.handles.epochSelectionAxes,'LooseInset',get(obj.handles.isoAxes,'TightInset'))
            end
            

            % display model output
            if ~isempty(obj.modelCoefs)
                fprintf('LM fit coefs (P-val log10): UV: %.2g (%.1g) Green: %.2g (%.1g)\n', obj.modelCoefs(3,1), log10(obj.modelCoefs(3,2)), obj.modelCoefs(2,1), log10(obj.modelCoefs(2,2)));
                obj.handles.dataDisplayText.String = sprintf('LM fit coefs (P-val log10): UV: %.2g (%.1g) Green: %.2g (%.1g)', obj.modelCoefs(3,1), log10(obj.modelCoefs(3,2)), obj.modelCoefs(2,1), log10(obj.modelCoefs(2,2)));
            end
        end
        
        function dataTableSelect(obj, ~, data)
            if size(data.Indices, 1) == 0 % happens on a deselect from a ui redraw
                return
            end
            responsePointIndex = data.Indices(1);
            point = obj.pointData(responsePointIndex, 1:2);
            obj.selectedPoint = point;
            obj.updateUi();
        end
        
        function singlePointTableSelect(obj, tab, data)
            if size(data.Indices, 1) == 0 % happens on a deselect from a ui redraw
                return
            end
            tableRow = data.Indices(1);
            ei = tab.Data(tableRow, 1);
            obj.epochData{ei}.ignore = true;
            fprintf('ignoring epoch %g in this analysis\n', ei);
            obj.analyzeData();
            obj.updateUi();
        end
        
        function isoPlotPointClick(obj, ~, ~, index)
            obj.selectedPoint = obj.pointData(index, 1:2);
            obj.updateUi();
        end
        
        function clearFigure(obj)
            obj.resetPlots();
            clearFigure@FigureHandler(obj);
        end
        
        function resetPlots(obj)
            obj.epochData = {};
            obj.epochIndex = 0;
            obj.pointData = [];
            obj.interpolant = [];
            obj.nextStimulus = [];
            obj.nextStimulusInfo = {};
            obj.selectedPoint = [];
            obj.protocolShouldStop = false;
        end
        
        function crange = get.contrastRange1(obj)
            crange = [-1, (1 / obj.baseIntensity1) - 1];
        end
        function crange = get.contrastRange2(obj)
            crange = [-1, (1 / obj.baseIntensity2) - 1];
        end        
        
%         function show(obj)
%             show@symphonyui.core.FigureHandler(obj);
%             obj.waitIfNecessary()
%         end
        
    end
    
%     
%     methods (Static)
%         function settings = storedSettings(stuffToStore)
%             % This method stores means across figure handlers.
% 
%             persistent stored;
%             if nargin > 0
%                 stored = stuffToStore
%             end
%             settings = stored
%         end
%         
%     end
    
end