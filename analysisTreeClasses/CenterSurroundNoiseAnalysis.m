classdef CenterSurroundNoiseAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
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
            epochIndices
            
            return

            

            
            % loop through epochs, regenerate stim, and compare linear prediction to response

            
        end
    end
    
    methods(Static)
        
        function plotMeanTraces(node, cellData)
            
        end
    end
end