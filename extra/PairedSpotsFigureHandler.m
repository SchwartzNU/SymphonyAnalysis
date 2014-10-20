% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the mean response line. The default is blue.

classdef PairedSpotsFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Paired Spots'
    end
    
    properties
        deviceName
        lineColor
        stimStart %data point
        stimEnd %data point
        meanPlots   % array of structures to store the properties of each class of epoch.
        singleSpotMeans = {};
        singleSpotMeans_N = []; %number of epochs
        pairMeans = {};
        pairMeans_N = [];
        pairDist = [];
        componentSpotIDs = [];
        splot = []; %handles for subplots
        xVals = [];
        plotRows
        plotCols
    end
    
    methods
        
        function obj = PairedSpotsFigureHandler(protocolPlugin, deviceName, varargin)           
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
 
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto');

            %remove menubar
            set(obj.figureHandle, 'MenuBar', 'none');
            %make room for labels
            set(obj.axesHandle(), 'Position',[0.14 0.18 0.72 0.72])
            
            obj.resetPlots();
        end
        
        
        function handleEpoch(obj, epoch)
            %focus on correct figure
            set(0, 'CurrentFigure', obj.figureHandle);
            
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end
            
            %subtract mean
            responseData = responseData - mean(responseData(1:obj.stimStart));
            
            %add data to the appropriate mean structure
            if epoch.getParameter('isPair') %paired spots
                ID = epoch.getParameter('pairID');
                if length(obj.pairMeans) < ID || isempty(obj.pairMeans{ID})
                    obj.pairMeans_N(ID) = 1;
                    obj.componentSpotIDs(:,ID) = [epoch.getParameter('spot1ID'); epoch.getParameter('spot2ID')];
                    obj.pairDist(ID) = epoch.getParameter('pairDistance');
                    obj.pairMeans{ID} = responseData;
                    if ID==1 %compute X data only once                        
                        obj.xVals = (1:length(responseData)) ./ sampleRate;
                        %and get rows and columns of subplot                        
                        obj.plotRows = round(sqrt(epoch.getParameter('Npairs')));
                        obj.plotCols = ceil(epoch.getParameter('Npairs')/obj.plotRows);
                    end
                else
                    obj.pairMeans_N(ID) = obj.pairMeans_N(ID) + 1;
                    obj.pairMeans{ID} = obj.pairMeans{ID} + responseData/obj.pairMeans_N(ID);
                end
            else %single spot
                ID = epoch.getParameter('spot1ID');
                if length(obj.singleSpotMeans) < ID || isempty(obj.singleSpotMeans{ID})
                    obj.singleSpotMeans_N(ID) = 1;
                    obj.singleSpotMeans{ID} = responseData;
                else
                    obj.singleSpotMeans_N(ID) = obj.singleSpotMeans_N(ID) + 1;
                    obj.singleSpotMeans{ID} = obj.singleSpotMeans{ID} + responseData/obj.singleSpotMeans_N(ID);
                end
            end
            
            %obj.singleSpotMeans_N
            %obj.pairMeans_N
            
            %make plots
            L = length(obj.pairMeans);
            for i=1:L
                obj.splot(i) = subplot(obj.plotRows,obj.plotCols,i,'replace','Parent',obj.figureHandle);
                hold(obj.splot(i),'on');
                plot(obj.splot(i),obj.xVals,obj.singleSpotMeans{obj.componentSpotIDs(1,i)},'Color','k','LineStyle','-'); 
                plot(obj.splot(i),obj.xVals,obj.singleSpotMeans{obj.componentSpotIDs(2,i)},'Color','k','LineStyle','-'); 
                plot(obj.splot(i),obj.xVals,obj.singleSpotMeans{obj.componentSpotIDs(1,i)}+obj.singleSpotMeans{obj.componentSpotIDs(2,i)},'Color','b','LineStyle','--'); 
                plot(obj.splot(i),obj.xVals,obj.pairMeans{i},'Color','r','LineStyle','-'); 
                title(obj.splot(i), ['Distance = ' num2str(obj.pairDist(i)) ' um']);
                hold(obj.splot(i),'off');
            end
    
        end
        
        function saveFigureData(obj,fname)
            data.singleSpotMeans = obj.singleSpotMeans;
            data.singleSpotMeans_N = obj.singleSpotMeans_N;
            data.pairMeans = obj.pairMeans;
            data.pairMeans_N = obj.pairMeans_N;
            data.pairDist = obj.pairDist;
            data.componentSpotIDs = obj.componentSpotIDs;
            data.xVals = obj.xVals;
            save(fname,'data');
        end
        
        function clearFigure(obj)
            obj.resetPlots();
            
            clearFigure@FigureHandler(obj);
        end
        
        
        function resetPlots(obj)
            obj.meanPlots = struct('params', {}, ...        % The params that define this class of epochs.
                'data', {}, ...          % The mean of all responses of this class.
                'sampleRate', {}, ...    % The sampling rate of the mean response.
                'units', {}, ...         % The units of the mean response.
                'count', {}, ...         % The number of responses used to calculate the mean reponse.
                'plotHandle', {});       % The handle of the plot for the mean response of this class.
            obj.singleSpotMeans = {};
            obj.singleSpotMeans_N = []; %number of epochs
            obj.pairMeans = {};
            obj.pairMeans_N = [];
            obj.pairDist = [];
            obj.componentSpotIDs = [];
            obj.splot = []; %handles for subplots
            obj.xVals = [];           
        end
        
    end
    
end