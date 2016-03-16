classdef CurrentOrVoltagePulseAnalysis < AnalysisTree
    properties

    end
    
    methods
        function obj = CurrentOrVoltagePulseAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': CurrentOrVoltagePulseAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'pulseAmplitude', 'amp1HoldSignal', 'amp2HoldSignal'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'pulseAmplitude'});
        end
        
        function obj = doAnalysis(obj, cellData)
            %nothing to do here
        end
        
    end
    
    methods(Static)
        
        function plotMeanTrace(node, cellData)
            rootData = node.get(1);
            epochInd = node.get(2).epochID;
            cellData.plotMeanData(epochInd, true, [], rootData.deviceName);
        end
        
    end
    
end