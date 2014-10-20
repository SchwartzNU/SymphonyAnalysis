classdef LightStepAnalysis < AnalysisTree
    properties
        
        StartTime = 0;
        EndTime = 1000;
        respType = 'Peak';
        
    end
    
    methods
        function obj = LightStepAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.rawfilename ': ' dataSetName ': LightStepAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'spotSize', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'RstarMean'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            allBaselineSpikes = []; 
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [baselineSpikes, respUnits, baselineLen] = getEpochResponses(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    [spikes, respUnits, intervalLen] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(spikes);
                    %'EndTime', 250);
                else
                    N = 0;
                end    
                                
                curNode.N = N;
                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    allBaselineSpikes = [allBaselineSpikes, baselineSpikes];
                    curNode.spikes = spikes;
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            %subtract baseline
            baselineMean = mean(allBaselineSpikes);
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                for i=1:L
                    curNode = obj.get(leafIDs(i));
                    curNode.resp = curNode.spikes - (baselineMean * intervalLen/baselineLen);
                    curNode.respMean = mean(curNode.resp);
                    curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
        end
        
    end
    
    methods(Static)
        
        function plotMeanTrace(node, cellData)
            rootData = node.get(1);
            epochInd = node.get(2).epochID;
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                cellData.plotPSTH(epochInd, 10, rootData.deviceName);
            else
                cellData.plotMeanData(epochInd, true, [], rootData.deviceName);
            end            
        end
        
    end
    
end