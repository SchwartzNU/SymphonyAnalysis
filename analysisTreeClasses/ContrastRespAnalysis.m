classdef ContrastRespAnalysis < AnalysisTree
    properties
        
    end
    
    methods
        function obj = ContrastRespAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': ContrastRespAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam, 'spotSize', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'contrast'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'contrast');
            
            %baseline subtraction and normalization (factor out in the
            %future?
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                for i=1:L %for each leaf node
                    curNode = obj.get(leafIDs(i));
                    %baseline subtraction
                    grandBaselineMean = outputStruct.baselineRate.mean_c;
                    tempStruct.ONSETrespRate_grandBaselineSubtracted = curNode.ONSETrespRate;
                    tempStruct.ONSETrespRate_grandBaselineSubtracted.value = curNode.ONSETrespRate.value - grandBaselineMean;
                    tempStruct.OFFSETrespRate_grandBaselineSubtracted = curNode.OFFSETrespRate;
                    tempStruct.OFFSETrespRate_grandBaselineSubtracted.value = curNode.OFFSETrespRate.value - grandBaselineMean;
                    tempStruct.ONSETspikes_grandBaselineSubtracted = curNode.ONSETspikes;
                    tempStruct.ONSETspikes_grandBaselineSubtracted.value = curNode.ONSETspikes.value - grandBaselineMean.*curNode.ONSETrespDuration.value; %fix nan and INF here
                    tempStruct.OFFSETspikes_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*curNode.OFFSETrespDuration.value;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted = curNode.spikeCount_ONSET_400ms;
                    tempStruct.ONSETspikes_400ms_grandBaselineSubtracted.value = curNode.spikeCount_ONSET_400ms.value - grandBaselineMean.*0.4; %fix nan and INF here
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted = curNode.OFFSETspikes;
                    tempStruct.OFFSETspikes_400ms_grandBaselineSubtracted.value = curNode.OFFSETspikes.value - grandBaselineMean.*0.4;
                    tempStruct = getEpochResponseStats(tempStruct);
                    
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            %             toNormList = {...
            %                 'ONSETrespRate_grandBaselineSubtracted', 'OFFSETrespRate_grandBaselineSubtracted', ...
            %                 'ONSETspikes_grandBaselineSubtracted', 'OFFSETspikes_grandBaselineSubtracted', ...
            %                 'ONSETrespRate', 'OFFSETrespRate', ...
            %                 'ONSETspikes', 'OFFSETspikes', ...
            %                 'ONSET_FRmax', 'OFFSET_FRmax', ...
            %                 'ONSETpeakInstantaneousFR', 'OFFSETpeakInstantaneousFR', ...
            %                 };
            %
            %             %normalization
            %             curNode = addNormalizedFields(curNode, toNormList);
            %
            %             for i=1:length(toNormList)
            %                toNormList{i} = [toNormList{i} '_norm'];
            %             end
            %
            %             [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            %             obj = obj.percolateUp(leafIDs, toNormList, toNormList);
            
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'contrast'};
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
        
        function plot_contrastVsspikeCount_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField(1).units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval (' yField.units ')']);
        end
        
        function plot_contrastVsspikeCount_stimInterval_baselineSubtracted(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_stimInterval_baselineSubtracted;
            if strcmp(yField(1).units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_stimInterval_baselineSubtracted (' yField.units ')']);
        end
        
        function plot_contrastVsspikeCount_ONSET_400ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.spikeCount_ONSET_400ms;
            if strcmp(yField(1).units, 's')
                
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['spikeCount_ONSET_400ms (' yField.units ')']);
        end
        
        function plot_contrastVsONSET_avgTracePeak(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSET_avgTracePeak;
            yvals = yField.value;
            plot(xvals, yvals, 'bx-');
            xlabel('contrast');
            ylabel(['ONSET_avgTracePeak (' yField.units ')']);
        end
        
        function plot_contrastVsONSET_chargeT25(node, cellData)
            rootData = node.get(1);
            xvals = rootData.contrast;
            yField = rootData.ONSET_chargeT25;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('contrast');
            ylabel(['ONSET_chargeT25 (' yField.units ')']);
        end
        
        function plotData(node, cellData)
            rootData = node.get(1);
            errorbar(rootData.contrast, rootData.respMean, rootData.respSEM);
            xlabel('Contrast');
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                ylabel('Spike count (norm)');
            else
                ylabel('Charge (pC)');
            end
        end
        
    end
    
end