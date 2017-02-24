classdef ColorResponseAnalysis < AnalysisTree
    properties
        
    end
    
    methods
        function obj = ColorResponseAnalysis(cellData, dataSetName, params)
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
                {'RstarMean', params.ampModeParam});
            obj = obj.buildCellTree(1, cellData, dataSet, {'colorChangeMode', 'colorPattern2', 'intensity2'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c;
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'contrast', 'sortColors');
                            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
                        
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'baseColor'};
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
        
%         function plot_colorRatioVsONSETspikes(node, ~)
%             rootData = node.get(1);
%             xvals = rootData.contrast;
%             yField = rootData.ONSETspikes;
%             if strcmp(yField(1).units, 's')
%                 yvals = yField.median_c;
%             else
%                 yvals = yField.mean_c;
%             end
%             errs = yField.SEM;
%             errorbar(xvals, yvals, errs);
%             xlabel('color');
%             ylabel(['ONSETspikes (' yField.units ')']);
%         end
%         
%         function plot_colorRatioVsOFFSETspikes(node, ~)
%             rootData = node.get(1);
%             xvals = rootData.contrast;
%             yField = rootData.OFFSETspikes;
%             if strcmp(yField(1).units, 's')
%                 yvals = yField.median_c;
%             else
%                 yvals = yField.mean_c;
%             end
%             errs = yField.SEM;
%             errorbar(xvals, yvals, errs);
%             xlabel('color');
%             ylabel(['OFFSETspikes (' yField.units ')']);
%         end        
%         
        function plot_ramp_ONSETspikes(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'ONSETspikes_mean');
        end
        
        function plot_ramp_ONSET_peak(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'ONSET_avgTracePeak_value');
        end
        
        function plot_ramp_stimInterval_charge(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'stimInterval_charge_mean');
        end        
        
        function plot_ramp_OFFSETspikes(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'OFFSETspikes_mean');
        end        
            
            
        function plot_ramp(tree, cellData, variableName)
            colorNodeIds = tree.getchildren(1);
            data = {};
            colors = {};
            for colornode = 1:length(colorNodeIds)
                colorData = struct();
                colorData.intensity = [];
                colorData.response = [];
                currentStepColorNode = tree.get(colorNodeIds(colornode));
                colors{colornode} = currentStepColorNode.splitValue;
                rampnodes = tree.getchildren(colorNodeIds(colornode));
                
                % get contrast from sample epoch
                
                for ri = 1:length(rampnodes)
                    datanode = tree.get(rampnodes(ri));
                    contrastepoch = cellData.epochs(datanode.epochID(1));
                    contrast = contrastepoch.get('contrast');
                    intensity = contrastepoch.get('intensity');
                    colorData.intensity(end+1) = ((datanode.splitValue - intensity) / intensity) / contrast;
                    colorData.response(end+1) = datanode.(variableName);
                end
                data{colornode} = colorData;
            end
            for ci = 1:length(colors)
                d = data{ci};
                switch colors{ci}
                    case 'uv'
                        color = [.3, 0, .9];
                    case 'blue'
                        color = [0, .5, 1];
                    case 'green'
                        color = [0, .8, .1];
                end
               
                plot(d.intensity, d.response, 'Color', color, 'LineWidth', 3);
               
                hold on
                
            end
%             legend(colors, 'Location', 'north')
            hold off
            xlabel('(varying : fixed) ratio')
                
        end
    end
    
end


