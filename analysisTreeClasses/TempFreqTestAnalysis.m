classdef TempFreqTestAnalysis < AnalysisTree
    %v1, Adam 8/25/14
    properties
        StartTime = 0;
        EndTime = 0; %Setting to 0, getEpochResponses will set it's own default.
        respType = 'Charge';
        responsePeaks = 5;
    end
    
    methods
        function obj = TempFreqTestAnalysis_Adam(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': TempFreqTestAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);    
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'curFrequency'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            
            
            %Get baseline for response
            allLeavesEpochs = [];
            for i = 1:L  %OVER LEAFS
                curNode = obj.get(leafIDs(i));
                curLeafEpochs = curNode.epochID;
                allLeavesEpochs = [allLeavesEpochs, curLeafEpochs];
            end;    
                
            baselinePSTH = getEpochsBaseline_Adam_v2(cellData, allLeavesEpochs, ...
                'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
            
            for i=1:L
                %This loop gets responses (all leafs in tree).
                curNode = obj.get(leafIDs(i));
                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')

                    [RESP, sumRESP, respUnits] = getEpochResponses_tempFreq_Adam(cellData, curNode.epochID, 'Phase Plot' , 'DeviceName', rootData.deviceName, ...
                        'StartTime', obj.StartTime, 'EndTime', obj.EndTime, 'baselinePSTH', baselinePSTH, 'responsePeaks', obj.responsePeaks);
                
                else
                    disp('Analysis doesn''t support whole cell data yet...');
                    return
                    
                end
                N = length(RESP(:,1));
                
                %Save to node
                curNode.N = N;
                curNode.timeDelayMean = sumRESP.timeDelayMean;
                curNode.timeDelaySEM = sumRESP.timeDelaySEM;
                curNode.phaseDelayMean = sumRESP.phaseDelayMean;
                curNode.phaseDelaySEM = sumRESP.phaseDelaySEM;
               
                curNode.perCyclePhase = sumRESP.perCyclePhase;
                curNode.perCyclePsthMean = sumRESP.perCyclePsthMean; 
                curNode.perCyclePsthSEM = sumRESP.perCyclePsthSEM ;
                
                curNode.perCycleInPhaseMax =  sumRESP.perCycleInPhaseMax;
                curNode.perCycleInPhaseMaxSEM =  sumRESP.perCycleInPhaseMaxSEM;
                curNode.perCycleOutOfPhaseMax =  sumRESP.perCycleOutOfPhaseMax;
                curNode.perCycleOutOfPhaseMaxSEM =  sumRESP.perCycleOutOfPhaseMaxSEM;
                
                curNode.inPhaseMax_CycleAve = sumRESP.inPhaseMax_CycleAve;
                curNode.inPhaseMax_CycleSEM = sumRESP.inPhaseMax_CycleSEM;
                curNode.outOfPhaseMax_CycleAve = sumRESP.outOfPhaseMax_CycleAve;
                curNode.outOfPhaseMax_CycleSEM = sumRESP.outOfPhaseMax_CycleSEM;
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'timeDelayMean','timeDelayMean',... 
                'timeDelaySEM','timeDelaySEM',... 
                'phaseDelayMean','phaseDelayMean',... 
                'phaseDelaySEM','phaseDelaySEM',...
                'perCycleInPhaseMax', 'perCycleInPhaseMax',...
                'perCycleInPhaseMaxSEM', 'perCycleInPhaseMaxSEM',...
                'perCycleOutOfPhaseMax', 'perCycleOutOfPhaseMax',...
                'perCycleOutOfPhaseMaxSEM', 'perCycleOutOfPhaseMaxSEM',...
                'inPhaseMax_CycleAve','inPhaseMax_CycleAve',...
                'inPhaseMax_CycleSEM','inPhaseMax_CycleSEM',...
                'outOfPhaseMax_CycleAve','outOfPhaseMax_CycleAve',...
                'outOfPhaseMax_CycleSEM','outOfPhaseMax_CycleSEM',...               
                'splitValue', 'Frequency');
        end        
    end
    

    
    
    methods(Static)
        
        function plotData_PeakCycleAverage(node, cellData)
            rootData = node.get(1);
            errorbar(log10(rootData.Frequency), rootData.inPhaseMax_CycleAve, rootData.inPhaseMax_CycleSEM);
            hold on;
            errorbar(log10(rootData.Frequency), rootData.outOfPhaseMax_CycleAve, rootData.outOfPhaseMax_CycleSEM,'r');
            hold off;
            title('In Phase: Blue    In Anti-Phase: Red');
            %ON and OFF peaks or vice-versa
            xlabel('log10 of Frequency (Hz)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Peak Firing Rate (Cycle Average)');
            else
                ylabel('Charge (pC)');
            end
        end
              
        function plotData_PeakByCycle_inPhase(node, cellData)
            rootData = node.get(1);
            numLeaves = length(rootData.Frequency);
            numCycles = length(rootData.perCycleInPhaseMax)/numLeaves; %including ghost cycle
           
            hold on;
            for cyc = 1:numCycles
                errorbar(log10(rootData.Frequency),...
                    rootData.perCycleInPhaseMax(cyc:numCycles:end),...
                    rootData.perCycleInPhaseMaxSEM(cyc:numCycles:end), 'Color', [(cyc-1)/numCycles 0 1-(cyc-1)/numCycles]);
            end;
            hold off;
            xlabel('log10 of Frequency (Hz)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Peak Firing Rate for Each Cycle');
            else
                ylabel('Charge (pC)');
            end
        end
        
        function plotData_PeakByCycle_outOfPhase(node, cellData)
            rootData = node.get(1);
            numLeaves = length(rootData.Frequency);
            numCycles = length(rootData.perCycleInPhaseMax)/numLeaves; %including ghost cycle
           
            hold on;
            for cyc = 1:numCycles
                errorbar(log10(rootData.Frequency),...
                    rootData.perCycleOutOfPhaseMax(cyc:numCycles:end),...
                    rootData.perCycleOutOfPhaseMaxSEM(cyc:numCycles:end), 'Color', [(cyc-1)/numCycles 0 1-(cyc-1)/numCycles]);
            end;
            hold off;
            xlabel('log10 of Frequency (Hz)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Peak Firing Rate for Each Cycle');
            else
                ylabel('Charge (pC)');
            end
        end
  
        function plotLeaf(node, cellData)
            %Phase plots
            LeafData = node.get(1);
            xlabel('Phase');
            ylabel('PSTH');
            
            numCycles = length(LeafData.perCyclePsthMean(:,1));
            %All cycles in data (including "ghost");
            
            for cycle = 1:numCycles
                plot(LeafData.perCyclePhase, LeafData.perCyclePsthMean(cycle,:),...
                    'Color', [(cycle-1)/numCycles 0 1-(cycle-1)/numCycles]);
                hold on;
            end;
            hold off;
        end
        
        function plotData_PhaseDelay(node, cellData)
            rootData = node.get(1);
            errorbar(log10(rootData.Frequency), rootData.phaseDelayMean, rootData.phaseDelaySEM);
            xlabel('log10 of Frequency (Hz)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Phase Delay (degrees)');
            else
                ylabel('Charge (pC)');
            end
        end
        
        function plotData_TimeDelay(node, cellData)
            rootData = node.get(1);
            errorbar(log10(rootData.Frequency), rootData.timeDelayMean, rootData.timeDelaySEM);
            xlabel('log10 of Frequency (Hz)');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Time Delay (s)');
            else
                ylabel('Charge (pC)');
            end
        end
       
        
    end
    
end