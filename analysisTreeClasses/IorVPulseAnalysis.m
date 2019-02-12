classdef IorVPulseAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 1000;
    end
    
    methods
        function obj = IorVPulseAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': IorVAnalysis'];
            obj = obj.setName(nameStr);
            obj = obj.copyAnalysisParams(params);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'curPulseAmp', 'pulseAmplitude'});
            rootData = obj.get(1);
            if isnan(rootData.pulseAmplitude)
                obj = obj.buildCellTree(1, cellData, dataSet, {'curPulseAmp'});
            else
                obj = obj.buildCellTree(1, cellData, dataSet, {'pulseAmplitude'});
            end
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                    'DeviceName', rootData.deviceName);
                outputStruct = getEpochResponseStats(outputStruct);
                curNode = mergeIntoNode(curNode, outputStruct);
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'pulseAmp');
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            rootData = obj.get(1);
            rootData.stimParameterList = {'pulseAmp'};
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            obj = obj.set(1, rootData);
            
        end
        
    end
    
    methods(Static)
        
        function plot_pulseAmplitudeVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.pulseAmp;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            plot(xvals, yvals, 'x-');
            xlabel('pulseAmp');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
        end
        
        function plot_pulseAmplitudeVsONSETtransPeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.pulseAmp;
            yField = rootData.ONSETtransPeak;
            yvals = yField.mean;
            plot(xvals, yvals, 'x-');
            xlabel('pulseAmp');
            ylabel(['ONSETtransPeak (' yField.units ')']);
        end
        
        function plot_pulseAmplitudeVsONSETsusPeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.pulseAmp;
            yField = rootData.ONSETsusPeak;
            yvals = yField.mean;
            plot(xvals, yvals, 'x-');
            xlabel('pulseAmp');
            ylabel(['ONSETsusPeak (' yField.units ')']);
        end
        
        function plot_pulseAmplitudeVsONSET_last200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.pulseAmp;
            yField = rootData.ONSET_last200ms;
            yvals = yField.mean;
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            
            
%             plot(xvals, yvals, 'x-');
            xlabel('pulseAmp');
            ylabel(['ONSET_last200ms (' yField.units ')']);
        end        
        
        function plotMeanTraces(node, cellData)
            rootData = node.get(1);
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca();
            for i=1:L
                hold(ax, 'on');
                epochInd = node.get(chInd(i)).epochID;
                cellData.plotMeanData(epochInd, true, [], rootData.deviceName, ax);
            end
            hold(ax, 'off');
        end
        
    end
    
end