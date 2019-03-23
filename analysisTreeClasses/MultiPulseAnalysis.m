classdef MultiPulseAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = MultiPulseAnalysis(cellData, dataSetName, params)
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
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': MultiPulseAnalysis'];            
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam, 'intensity', 'stepByStim', 'pulse1Curr', 'pulse2Curr', 'offsetX', 'offsetY'});
            if strcmp(obj.Node{1}.stepByStim, 'Stim 1')
                obj = obj.buildCellTree(1, cellData, dataSet, {'pulse1Curr'});
            else
                obj = obj.buildCellTree(1, cellData, dataSet, {'pulse2Curr'});
            end            
        end
        
        function obj = doAnalysis(obj, cellData)
           rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                % this is all correct
                curNode = obj.get(leafIDs(i));
                % get CA data
%                 outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
%                     'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
%                     'FitPSTH', 0);
%                 outputStruct = getEpochResponseStats(outputStruct);
%                 curNode = mergeIntoNode(curNode, outputStruct);
                % get WC data
                outputStruct = getEpochResponses_actionCurrents_WC(cellData, curNode.epochID, ...
                    'DeviceName', rootData.deviceName);
                outputStruct = getEpochResponseStats(outputStruct);
                curNode = mergeIntoNode(curNode, outputStruct);
                % get WC action current data
%                 if rootData.(rootData.holdSignalParam) == -60 % is voltage clamp?
%                     outputStruct = getEpochResponses_actionCurrents_WC(cellData, curNode.epochID, ...
%                         'DeviceName', rootData.deviceName);
%                     outputStruct = getEpochResponseStats(outputStruct);
%                     curNode = mergeIntoNode(curNode, outputStruct);
%                 end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'pulse2Curr');
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'pulse1Curr');
   

            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);

        end
    end
    
    methods(Static)

        function plotMeanTraces(node, cellData)
            rootData = node.get(1);
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            for i=1:L
                epochInd = node.get(chInd(i)).epochID;
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    cellData.plotPSTH(epochInd, 10, rootData.deviceName, ax);
                else
                    cellData.plotMeanData(epochInd, false, [], rootData.deviceName, ax);
                end
                hold(ax, 'on');               
            end
            hold(ax, 'off');
        end
        
        function plot_ampHoldSignalvStim1SpikeCount(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = ones(1, L)*NaN;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                if strcmp(rootData.stepByStim, 'Stim 1')
                    xvals(i) = chData.stepsStim1.value;
                elseif strcmp(rootData.stepByStim, 'Stim 2')
                    xvals(i) = chData.stepsStim2.value;
                end
                yvals(i) = chData.stim1_spikeCount.mean;
                errs(i) = chData.stim1_spikeCount.SEM;              
            end
            errorbar(xvals, yvals, errs);
            xlabel(['Step By Stim:' rootData.stepByStim])
            ylabel('Spike Count')
        end
        
        function plot_ampHoldSignalvStim2SpikeCount(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = ones(1, L)*NaN;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                if strcmp(rootData.stepByStim, 'Stim 1')
                    xvals(i) = chData.stepsStim1.value;
                elseif strcmp(rootData.stepByStim, 'Stim 2')
                    xvals(i) = chData.stepsStim2.value;
                end
                yvals(i) = chData.stim2_spikeCount.mean;
                errs(i) = chData.stim2_spikeCount.SEM;              
            end
            errorbar(xvals, yvals, errs);
            xlabel(['Step By Stim:' rootData.stepByStim])
            ylabel('Spike Count')
        end
        
        function plot_ampHoldSignalvStim1FirstSpikeAmp(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = ones(1, L)*NaN;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                if strcmp(rootData.stepByStim, 'Stim 1')
                    xvals(i) = chData.stepsStim1.value;
                elseif strcmp(rootData.stepByStim, 'Stim 2')
                    xvals(i) = chData.stepsStim2.value;
                end
                yvals(i) = chData.stim1_firstSpikeHeight.mean;
                errs(i) = chData.stim1_firstSpikeHeight.SEM;              
            end
            errorbar(xvals, yvals, errs);
            xlabel(['Step By Stim:' rootData.stepByStim])
            ylabel('Spike Count')
        end
        
        function plot_ampHoldSignalvStim2FirstSpikeAmp(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = ones(1, L)*NaN;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                if strcmp(rootData.stepByStim, 'Stim 1')
                    xvals(i) = chData.stepsStim1.value;
                elseif strcmp(rootData.stepByStim, 'Stim 2')
                    xvals(i) = chData.stepsStim2.value;
                end
                yvals(i) = chData.stim2_firstSpikeHeight.mean;
                errs(i) = chData.stim2_firstSpikeHeight.SEM;              
            end
            errorbar(xvals, yvals, errs);
            xlabel(['Step By Stim:' rootData.stepByStim])
            ylabel('Spike Count')
        end
        
        
    end
end

