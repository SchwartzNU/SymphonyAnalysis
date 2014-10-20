% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the response line. The default is blue.

classdef ResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Response'
    end
    
    properties
        plotHandle
        deviceName
        lineColor
        stimStart
        stimEnd
    end
    
    methods
        
        function obj = ResponseFigureHandler(protocolPlugin, deviceName, varargin)            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('LineColor', 'b', @(x)ischar(x) || isvector(x));
            ip.addParamValue('StartTime', 0, @(x)isnumeric(x));
            ip.addParamValue('EndTime', 0, @(x)isnumeric(x));
            
            % Allow deviceName to be an optional parameter.
            % inputParser.addOptional does not fully work with string variables.
            if nargin > 1 && any(strcmp(deviceName, ip.Parameters))
                varargin = [deviceName varargin];
                deviceName = [];
            end
            if nargin == 1
                deviceName = [];
            end
            
            ip.parse(varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName = deviceName;
            obj.lineColor = ip.Results.LineColor;
            obj.stimStart = ip.Results.StartTime;
            obj.stimEnd = ip.Results.EndTime;
            
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end   
                        
            obj.plotHandle = plot(obj.axesHandle(), 1:100, zeros(1, 100), 'Color', obj.lineColor);
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto'); 
            
            %remove menubar
            set(obj.figureHandle, 'MenuBar', 'none');
            %make room for labels
            set(obj.axesHandle, 'Position',[0.14 0.18 0.72 0.72])
        end
        
        
        function handleEpoch(obj, epoch)
            %focus on correct figure
            set(0, 'CurrentFigure', obj.figureHandle);
            
            % Update the figure title with the epoch number and any parameters that are different from the protocol default.
            epochParams = obj.protocolPlugin.epochSpecificParameters(epoch);
            paramsText = '';
            if ~isempty(epochParams)
                for field = sort(fieldnames(epochParams))'
                    paramValue = epochParams.(field{1});
                    if islogical(paramValue)
                        if paramValue
                            paramValue = 'True';
                        else
                            paramValue = 'False';
                        end
                    elseif isnumeric(paramValue)
                        paramValue = num2str(paramValue);
                    end
                    paramsText = [paramsText ', ' humanReadableParameterName(field{1}) ' = ' paramValue]; %#ok<AGROW>
                end
            end
            %set(get(obj.axesHandle(), 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.numEpochsCompleted) paramsText]);
            set(get(obj.axesHandle(), 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.numEpochsCompleted)]);
            
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end
            
            % Plot the response
            if isempty(responseData)
                text(0.5, 0.5, 'no response data available', 'FontSize', 12, 'HorizontalAlignment', 'center');
            else
                set(obj.plotHandle, 'XData', (1:numel(responseData))/sampleRate, ...
                                    'YData', responseData);
                                
                %add start and end lines
                %put in start and end lines
                limVec = get(obj.axesHandle(),'ylim');
                plotMin = limVec(1);
                plotMax = limVec(2);
            
                lstart = line('Xdata', [obj.stimStart obj.stimStart] / sampleRate, ...
                    'Ydata', [plotMin, plotMax], ...
                    'Color', 'k', 'LineStyle', '--');
                lend = line('Xdata', [obj.stimEnd obj.stimEnd] / sampleRate, ...
                    'Ydata', [plotMin, plotMax], ...
                    'Color', 'k', 'LineStyle', '--');
                set(lstart,'Parent',obj.axesHandle());
                set(lend,'Parent',obj.axesHandle());
                ylabel(obj.axesHandle(), units, 'Interpreter', 'none');
                xlabel(obj.axesHandle(), 'Time (s)');
                
                %auto scale
                set(obj.axesHandle(), 'ylim', [min(responseData)-.05*abs(min(responseData)), max(responseData)+.05*abs(max(responseData))]);
            end
        end
        
        function saveFigureData(obj,fname)
             saveas(obj.figureHandle,fname,'pdf');
        end
        
        
        function clearFigure(obj)
            clearFigure@FigureHandler(obj);
            
            obj.plotHandle = plot(obj.axesHandle(), 1:100, zeros(1, 100), 'Color', obj.lineColor);
        end
        
    end
    
end