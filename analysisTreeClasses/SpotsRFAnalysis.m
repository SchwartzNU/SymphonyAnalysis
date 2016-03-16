classdef SpotsRFAnalysis < AnalysisTree
    properties
        StartTime = 0
        EndTime = 0;
        respType = 'Charge';
    end
    
    methods
        function obj = SpotsRFAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
                        
            nameStr = [cellData.rawfilename ': ' dataSetName ': SpotsRFAnalysis'];
            obj = obj.setName(nameStr);
            obj = obj.copyAnalysisParams(params);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {@(epoch)spotDistance(epoch), @(epoch)spotAngle(epoch)});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            allBaselineSpikes = []; 
            for i=1:L
                curNode = obj.get(leafIDs(i));
                curNode.X = cellData.epochs(curNode.epochID(1)).get('curShiftX');
                curNode.Y = cellData.epochs(curNode.epochID(1)).get('curShiftY');  
                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [baselineSpikes, respUnits, baselineLen] = getEpochResponses(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    [spikes, respUnits, intervalLen] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(spikes);
                else
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(resp);
                end
                
                curNode.N = N;
                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    allBaselineSpikes = [allBaselineSpikes, baselineSpikes];
                    curNode.spikes = spikes;
                else
                    curNode.resp = resp;
                    curNode.respMean = mean(resp);
                    curNode.respVar = var(resp);
                    curNode.respSEM = std(resp)./sqrt(N);
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
                    curNode.respVar = var(curNode.resp);
                    curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            %percolateUp to distance level
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'respVar', 'respVar', ...
                'N', 'N', ...
                'X', 'Xvals', ...
                'Y', 'Yvals', ...
                'splitValue', 'spotAngle');
        
            chInd = obj.getchildren(1); %distance nodes
            for i=1:length(chInd);
                curData = obj.get(chInd(i)); 
                curData.CV = std(curData.respMean) ./ abs(mean(curData.respMean));
                obj = obj.set(chInd(i), curData);
            end
        end        
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            chInd = node.getchildren(1); %distance nodes
            for i=1:length(chInd);
                curData = node.get(chInd(i));
                scatter(curData.Xvals, curData.Yvals, 70, curData.respMean, 'fill');
                hold('on');
            end
            %colorbar('location', 'SouthOutside');                       
            title('Spots RF map');            
            xlabel('X (microns)');
            ylabel('Y (microns)');
            %hold('off');
        end

        
    end
    
end