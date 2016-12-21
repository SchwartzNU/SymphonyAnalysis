classdef CenterSurroundNoiseAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
        modelStruct
    end
    
    methods
        function obj = CenterSurroundNoiseAnalysis(cellData, dataSetName, params)
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
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': WhiteNoiseFlickerAnalysis'];
            obj = obj.setName(nameStr); 
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam});
            obj = obj.buildCellTree(1, cellData, dataSet, {'ampMode'});
        end
        
        function obj = doAnalysis(obj, cellData)
            
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            mainLeaf = leafIDs(1);
            node = obj.get(mainLeaf);
            
            numberOfEpochs = length(node.epochID);
            
            epochIndices = [];
            for ei=1:numberOfEpochs
                eid = node.epochID(ei);
                epoch = cellData.epochs(eid);
                stimulusAreaMode = epoch.get('currentStimulus');
                
                if strcmp(stimulusAreaMode, 'Center')
                    epochIndices(end+1) = eid;
                end
            end
           
            
%             obj.modelStruct = noiseFilter(cellData, epochIndices);
% 
%             
%             figure(197);clf;
%             allFilters = cell2mat(obj.modelStruct.filtersByEpoch);
%             mn = mean(allFilters);
%             se = std(allFilters)/sqrt(size(allFilters, 1));
%             plot([mn; mn+se; mn-se]', 'LineWidth', 1) %obj.modelStruct.timeByEpoch{1}, 
%             % hold off
%             title('Filter mean \{pm} sem')                  
            
        end
    end
    
    methods(Static)
        
        function plotMeanTraces(~, ~)
      
        end
    end
end