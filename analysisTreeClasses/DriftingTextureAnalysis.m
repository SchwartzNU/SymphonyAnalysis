classdef DriftingTextureAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = DriftingTextureAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': DriftingTextureAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'textureAngle'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'textureAngle');
            
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            

            %DSI, DSang, OSI, OSang
            rootData = obj.get(1);
            rootData = addDSIandOSI(rootData, 'textureAngle');
            rootData.stimParameterList = {'textureAngle'};
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;

%             spatialFreqLevelNodes = getTreeLevel(obj, 'spatialFreq');
%             for i=1:length(spatialFreqLevelNodes)
%                 nodeData = obj.get(spatialFreqLevelNodes(i));
%                 nodeData = addDSIandOSI(nodeData, 'gratingAngle');
%                 nodeData.stimParameterList = {'gratingAngle'};  
%                 nodeData.byEpochParamList = byEpochParamList;
%                 nodeData.singleValParamList = singleValParamList;
%                 nodeData.collectedParamList = collectedParamList;
%                 obj = obj.set(spatialFreqLevelNodes(i), nodeData); 
%             end            
            
            
            %OSI, OSang
            rootData = obj.get(1);
            rootData = addDSIandOSI(rootData, 'textureAngle');
%             rootData.stimParameterList = {'textureAngle'};
%             rootData.byEpochParamList = byEpochParamList;
%             rootData.singleValParamList = singleValParamList;
%             rootData.collectedParamList = collectedParamList;

            obj = obj.set(1, rootData);
        end
        
    end
    
    methods(Static)
        
        function plot_textureAngleVsspikeCount_stimAfter500ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.textureAngle;
            yField = rootData.spikeCount_stimAfter500ms;
            if strcmp(yField(1).units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            polarerror(xvals*pi/180, yvals, errs);

            
            hold on;
            polar([0 rootData.spikeCount_stimAfter500ms_DSang*pi/180], [0 (100*rootData.spikeCount_stimAfter500ms_DSI)], 'r-');
            polar([0 rootData.spikeCount_stimAfter500ms_OSang*pi/180], [0 (100*rootData.spikeCount_stimAfter500ms_OSI)], 'g-');
            xlabel('TextureAngle');
            ylabel(['spikeCount_stimAfter500ms (' yField(1).units ')']);
            addDsiOsiVarTitle(rootData, 'spikeCount_stimAfter500ms')
            hold off;


        end
        
        function plot_textureAngleVsStimToEnd_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.textureAngle;
            yField = rootData.stimToEnd_avgTracePeak;
            yvals = yField.value;
            polar(xvals*pi/180, yvals);

            polarerror(xvals*pi/180, yvals, zeros(1,length(xvals)));
            
            hold on;
            polar([0 rootData.stimToEnd_avgTracePeak_DSang*pi/180], [0 (100*rootData.stimToEnd_avgTracePeak_DSI)], 'r-');
            polar([0 rootData.stimToEnd_avgTracePeak_OSang*pi/180], [0 (100*rootData.stimToEnd_avgTracePeak_OSI)], 'g-');
            xlabel('TextureAngle');
            ylabel(['stimToEnd_avgTracePeak (' yField.units ')']);
            addDsiOsiVarTitle(rootData, 'stimToEnd_avgTracePeak')
            hold off;
        end        
    end
    
end