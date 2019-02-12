classdef AutoCenterAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = AutoCenterAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
                params.holdSignalParam = 'ampHoldSignal';
            else
                params.ampModeParam = 'amp2Mode';
                params.holdSignalParam = 'amp2HoldSignal';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': AutoCenterAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {params.ampModeParam, params.holdSignalParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'sessionId','presentationId'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.getchildren(1);
            L = length(leafIDs);
            for leaf_index = 1:L
                curNode = obj.get(leafIDs(leaf_index));
                

                outputStruct = getAutoCenterRF(cellData, curNode.epochID, rootData.deviceName);
                curNode = mergeIntoNode(curNode, outputStruct);
                
                obj = obj.set(leafIDs(leaf_index), curNode);
                
                [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
                obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
                obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
                obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            end
        end
    end
    
    methods(Static)
        
        
        function plotSpatial_tHalfMax(node, ~)
            
            nodeData = node.get(1);

            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(100);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'plotSpatial_tHalfMax');

                    end
                end
            end
        end
        
        function plot0Spatial_mean(node, ~)
            
            nodeData = node.get(1);

            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(101);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'plotSpatial_mean');

                    end
                end
            end
        end           

        function plot1Spatial_peak(node, ~)
            
            nodeData = node.get(1);

            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(102);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'plotSpatial_peak');

                    end
                end
            end
        end           
        
        function plot1Spatial_overlap(node, cellData)
            
            nodeData = node.get(1);

            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(102);clf;
                        analysisData = nodeData.analysisData.value;
                        options = struct();
                        
                        
                        
                        options.overlapThresoldPercentile = 80;
                        
                        
                        
                        
                        d = '/Users/sam/Google Drive/research/retina/spatial offset analysis/thresholdMaps/';
                        options.saveFileName = sprintf('%s%s %s', d, cellData.savedFileName, cellData.cellType);
                        plotShapeData(analysisData, 'overlap', options);

                    end
                end
            end
        end  
        
        
        function plotSubunit(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(12);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'subunit');
                    end
                end
            end
        end
        
%         function plotTemporalAlignment(node, ~)
%             
%             nodeData = node.get(1);
%                         
%             if isfield(nodeData, 'splitParam')
%                 if strcmp(nodeData.splitParam, 'sessionId')
%                     if isfield(nodeData.analysisData, 'value')
%                         figure(13);clf;
%                         analysisData = nodeData.analysisData.value;
%                         plotShapeData(analysisData, 'temporalAlignment');
%                     end
%                 end
%             end
%         end       

        function plotSpatialDiagnostics(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(14);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'spatialDiagnostics');
                    end
                end
            end
        end
        
        function plotWholeCell(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(15);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'wholeCell');
                    end
                end
            end
        end      
        
        
        function plot2TemporalResponses(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(16);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'temporalResponses');
                    end
                end
            end
        end 
        
        function plotPositionDifferenceAnalysis(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(17);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'positionDifferenceAnalysis');
                    end
                end
            end
        end         
        
        
        function plot3ResponsesByPosition(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(18);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'responsesByPosition');
                    end
                end
            end
        end
        
        function plotPrintParameters(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'printParameters');
                    end
                end
            end
        end     
        
        function plotAdaptationRegion(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(19);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'adaptationRegion');
                    end
                end
            end
        end     

        
        function plotSpatialOffset(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(20);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'spatialOffset');
                    end
                end
            end
        end     
        
        function plotSpatialOffset_OnOff(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(20);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'spatialOffset_onOff');
                    end
                end
            end
        end           

        function plotSaveData(node, ~)
            
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        analysisData = nodeData.analysisData.value;
                        save('analysisData.mat', 'analysisData');
                        disp('Saved as analysisData.mat');
                    end
                end
            end
        end          

        function plotTemporalComponents(node, ~)
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(20);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'temporalComponents');
                    end
                end
            end
        end          
        
        function plotSaveMaps(node, ~)
            nodeData = node.get(1);
                        
            if isfield(nodeData, 'splitParam')
                if strcmp(nodeData.splitParam, 'sessionId')
                    if isfield(nodeData.analysisData, 'value')
                        figure(20);clf;
                        analysisData = nodeData.analysisData.value;
                        plotShapeData(analysisData, 'plotSpatial_saveMaps');
                    end
                end
            end
        end              
        
    end
end

