classdef BarsMultiSpeedAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
        respType = 'Spike count';
        PSTH_bin_width = 25; %ms
    end
    
    methods
        function obj = BarsMultiSpeedAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': BarsMultiSpeedAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);    
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'curBitDepth', 'curSpeed'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            allBaselineSpikes = []; 
            allBaselineRates = [];
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(obj.respType, 'Spike count')
                    [baselineSpikes, respUnits, baselineLen] = getEpochResponses_old(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime, 'EndOffset', 0);
                    [spikes, respUnits, intervalLen(i)] = getEpochResponses_old(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime, 'EndOffset', 0);
                    N = length(spikes);
                elseif strcmp(obj.respType, 'Peak firing rate')
                    [baselineRate, respUnits] = getEpochResponses_old(cellData, curNode.epochID, 'Baseline firing rate', 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime, 'EndOffset', 0, 'BinWidth', obj.PSTH_bin_width);
                    [peakRate, respUnits] = getEpochResponses_old(cellData, curNode.epochID, 'Peak firing rate', 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime, 'EndOffset', 0, 'BinWidth', obj.PSTH_bin_width);
                    N = length(peakRate);
                else %whole cell - maybe 
                    [resp, respUnits] = getEpochResponses_old(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime, 'EndOffset', 0);
                    N = length(resp);
                end
                
                curNode.N = N;
                
                if strcmp(obj.respType, 'Spike count')
                    allBaselineSpikes = [allBaselineSpikes, baselineSpikes];
                    curNode.spikes = spikes;
                elseif strcmp(obj.respType, 'Peak firing rate')
                    allBaselineRates = [allBaselineRates, baselineRate];
                    curNode.peakRate = peakRate;
                else
                    curNode.resp = resp;
                    curNode.respMean = mean(resp);
                    curNode.respSEM = std(resp)./sqrt(N);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            %subtract baseline
            if strcmp(obj.respType, 'Spike count')
               baselineMean = mean(allBaselineSpikes);
                for i=1:L
                    curNode = obj.get(leafIDs(i));
                    curNode.resp = curNode.spikes - (baselineMean * intervalLen(i)/baselineLen);
                    curNode.resp = curNode.resp ./ intervalLen(i); %splitValue is speed, now spikes / s
                    curNode.respMean = mean(curNode.resp);
                    curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                    obj = obj.set(leafIDs(i), curNode);
                end
            elseif strcmp(obj.respType, 'Peak firing rate')
                baselineMean = mean(allBaselineRates);
                for i=1:L
                    curNode = obj.get(leafIDs(i));
                    curNode.resp = curNode.peakRate - baselineMean;                   
                    curNode.respMean = mean(curNode.resp);
                    curNode.respSEM = 0;
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
                                    
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'N', 'N', ...
                'splitValue', 'Speed');
            
            chInd = obj.getchildren(1); %bit depths
            if length(chInd)==2 %has both 2-bit and 8-bit data
                bit2node = obj.get(chInd(1));
                bit8node = obj.get(chInd(2));
                
                bit2node.respMean_norm = bit2node.respMean ./ max(bit2node.respMean);
                bit2node.respSEM_norm = bit2node.respSEM ./ max(bit2node.respMean);
                obj = obj.set(chInd(1), bit2node);
                
                bit8node.respMean_norm = bit8node.respMean ./ max(bit8node.respMean);
                bit8node.respSEM_norm = bit8node.respSEM ./ max(bit8node.respMean);
                obj = obj.set(chInd(2), bit8node);
                
                %make combined curve using 8 and 2 bit data
                speedOverlapInd = find(bit8node.Speed == bit2node.Speed(1));
                if length(bit2node.Speed) == length(bit8node.Speed(speedOverlapInd:end)) %check for complete data
                    combinedResp = bit8node.respMean;
                    combinedResp(speedOverlapInd:end) = bit2node.respMean;
                    combined_SEM = bit8node.respSEM;
                    combined_SEM(speedOverlapInd:end) = bit2node.respSEM;
                    
                    rootData.combinedResp_norm = combinedResp ./ max(combinedResp);
                    rootData.combinedSEM_norm = combined_SEM ./ max(combinedResp);
                    rootData.combinedResp = combinedResp;
                    rootData.combined_SEM = combined_SEM;
                    rootData.Speed = bit8node.Speed / 1000; %mm/s
                    
                    Xvals = min(rootData.Speed):.01:max(rootData.Speed);
                    combinedResp_fit = interp1(rootData.Speed,  rootData.combinedResp_norm, Xvals, 'pchip');
                    slope = diff(combinedResp_fit)./10; %units of fractional change per mm/s                    
                    
                    rootData.selectivityRange_up = Xvals(slope>.2E-3);
                    rootData.selectivityRange_down = Xvals(slope<-.2E-3);
                    
                    rootData.diffVals = diff(rootData.combinedResp_norm);
                    rootData.diffX = (rootData.Speed(1:end-1) + rootData.Speed(2:end)) ./ 2;
                    [rootData.maxSlope, maxLoc] = max(rootData.diffVals);
                    [rootData.minSlope, minLoc] = min(rootData.diffVals);
                    rootData.maxSlopeSpeed = rootData.diffX(maxLoc);
                    rootData.minSlopeSpeed = rootData.diffX(minLoc);
                    
                    %get response ranges
                    %first check for monotonically increasing values
                    rootData.range_down = ones(1,2) * nan;
                    rootData.range_up = ones(1,2) * nan;
                    [~, maxRespInd] = max(rootData.combinedResp_norm);     
                    p = getThresCross(rootData.combinedResp_norm(maxRespInd:end), 0.75, -1);
                    if ~isempty(p)
                        rootData.range_down(1) = interp1(rootData.combinedResp_norm(maxRespInd+p-2:maxRespInd+p-1), ...
                            rootData.Speed(maxRespInd+p-2:maxRespInd+p-1),.75,'linear',nan);
                    end
                    p = getThresCross(rootData.combinedResp_norm(maxRespInd:end), 0.25, -1);
                    if ~isempty(p)
                        rootData.range_down(2) = interp1(rootData.combinedResp_norm(maxRespInd+p-2:maxRespInd+p-1), ...
                            rootData.Speed(maxRespInd+p-2:maxRespInd+p-1),.25,'linear',nan);
                    end
                    
                    p = getThresCross(rootData.combinedResp_norm(1:maxRespInd), 0.25, 1);
                    if ~isempty(p)
                        rootData.range_up(1) = interp1(rootData.combinedResp_norm(p-1:p), ...
                            rootData.Speed(p-1:p),.25,'linear',nan);
                    end
                    p = getThresCross(rootData.combinedResp_norm(1:maxRespInd), 0.75, 1);
                    if ~isempty(p)
                        rootData.range_up(2) = interp1(rootData.combinedResp_norm(p-1:p), ...
                            rootData.Speed(p-1:p),.75,'linear',nan);
                    end                    
                    
                    obj = obj.set(1,rootData);
                end
            end
            
        end
        
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            if isfield(node.get(1), 'class') %root node
                chInd = node.getchildren(1); %bit depths
                bit2node = node.get(chInd(1));
                bit8node = node.get(chInd(2));
                errorbar(bit8node.Speed, bit8node.respMean, bit8node.respSEM, 'b');
                hold('on');
                errorbar(bit2node.Speed, bit2node.respMean, bit2node.respSEM, 'r');
                %plot(bit8node.Speed, bit8node.respMean(1).*bit8node.Speed./bit8node.Speed(1), 'k--');
                %plot(bit8node.Speed, bit8node.respMean(1).*bit8node.Speed, 'k--');
                hold('off');                
            else %single speed node
                curData = node.get(1);
                if curData.splitValue == 8
                    %hold('on');
                    errorbar(curData.Speed, curData.respMean, curData.respSEM, 'b');
                    %plot(curData.Speed, curData.respMean(1).*curData.Speed./curData.Speed(1), 'k--');
                    %hold('off');
                else
                    %hold('on');
                    errorbar(curData.Speed, curData.respMean, curData.respSEM, 'r');
                    %plot(curData.Speed, curData.respMean(1).*curData.Speed./curData.Speed(1), 'k--');
                    %hold('off');
                end
            end
            
            xlabel('Bar speed (microns/sec)');
            ylabel('Response (norm), spikes / s'); %assumes cell-attached for now
        end
        
    end
    
end