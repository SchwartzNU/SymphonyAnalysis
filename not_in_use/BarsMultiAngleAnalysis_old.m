classdef BarsMultiAngleAnalysis_old < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
        respType = 'Charge';
    end
    
    methods
        function obj = BarsMultiAngleAnalysis_old(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': BarsMultiAngleAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);    
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'barAngle'});
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
                    curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'N', 'N', ...
                'splitValue', 'BarAngle');
            
            %OSI, OSang
            rootData = obj.get(1);
            Nangles = length(rootData.BarAngle);
            R=0;
            ROrtn=0;
            
            for j=1:Nangles
                R=R+rootData.respMean(j);
                ROrtn = ROrtn + (rootData.respMean(j)*exp(2*sqrt(-1)*rootData.BarAngle(j)*pi/180));
            end
           
            OSI = abs(ROrtn/R);
            OSang = angle(ROrtn/R)*90/pi;
            
            if OSang < 0
                OSang = 180 + OSang;
            end
            
            rootData.OSI = OSI;
            rootData.OSang = OSang;
            obj = obj.set(1, rootData);
            
        end
        
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            rootData = node.get(1);
            errorbar(rootData.BarAngle, rootData.respMean, rootData.respSEM);
            xlabel('Bar angle (degrees)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Spike count (norm)');
            else
                ylabel('Peak (pA or mV)');
            end
            
            hold on;
            x = [rootData.OSang,rootData.OSang];
            y = [min(rootData.respMean),max(rootData.respMean)];
            plot(x,y);
            title(['OSI = ' num2str(rootData.OSI) ', OSang = ' num2str(rootData.OSang)]);
            hold off;
            
        end
        
    end
    
end