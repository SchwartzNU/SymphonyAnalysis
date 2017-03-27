classdef ColorIsoResponseAnalysis < AnalysisTree
    properties
        
    end
    
    methods
        function obj = ColorIsoResponseAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': ColorIsoResponseAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam, 'baseIntensity1','baseItensity2'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'epochNum'});
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
            
        end
    end
    
    methods(Static)

        function plot0_ramp_Spikes(tree, cellData)
            nodeIds = tree.getchildren(1);
            
            
            % get all responses and epoch ids
            epochIdByNode = [];
            responseByEpochId = [];
            for ni = 1:length(nodeIds)
                nodeId = nodeIds(ni);
                epochNode = tree.get(nodeId);
                epochIdByNode(end+1) = epochNode.epochID;
                responseByEpochId(epochNode.epochID) = epochNode.('spikeCount_stimInterval_mean');
            end
            
            
            % get all contrasts to figure out the fixed value
            allRampEpochs = [];
            contrasts = [];
            
            for ei = 1:length(epochIdByNode)
                id = epochIdByNode(ei);
                epoch = cellData.epochs(id);
                if ~strcmp(epoch.get('stimulusMode'), 'ramp')
                    continue
                end
                allRampEpochs(end+1) = id;
                contrasts(end+1) = epoch.get('contrast1');
                contrasts(end+1) = epoch.get('contrast2');
            end
            
            % separate the epochs by which color is varying
            fixedStepContrast = mode(contrasts);
            uvVaryingEpochs = [];
            greenVaryingEpochs = [];
            epochIsUvVarying = [];
            contrastRatios = [];
            responses = [];
            for ei = 1:length(allRampEpochs)
                id = allRampEpochs(ei);
                epoch = cellData.epochs(id);
                
                if epoch.get('contrast1') == fixedStepContrast
                    varyingPattern = 'colorPattern2';
                    contrastRatios(ei) = epoch.get('contrast2') / epoch.get('contrast1');
                else
                    varyingPattern = 'colorPattern1';
                    contrastRatios(ei) = epoch.get('contrast1') / epoch.get('contrast2');
                end
                if strcmp(epoch.get(varyingPattern), 'uv')
                    uvVaryingEpochs(ei) = id;
                    epochIsUvVarying(ei) = true;
                else
                    greenVaryingEpochs(ei) = id;
                    epochIsUvVarying(ei) = false;
                end
                responses(ei) = responseByEpochId(id);
            end

            epochIsUvVarying = epochIsUvVarying == 1;
            
            ax = gca();
            hold(ax, 'on');
            plot(ax, contrastRatios(epochIsUvVarying), responses(epochIsUvVarying), 'o', 'Color',[.3, 0, .9])
            plot(ax, contrastRatios(~epochIsUvVarying), responses(~epochIsUvVarying), 'o', 'Color',[0, .8, .1])
            hold(ax, 'off');
            
            % get all the responses by the contrast values
%             for ei = 1:length(uvVaryingEpochs)
%                 id = uvVaryingEpochs(ei);
%                 epoch = cellData.epochs(id);
%                 contrastRatio = 
        end
        
            
        function plot_ramp(tree, cellData, variables)
            legends = {};
            for vi = 1:length(variables)
                variableName = variables{vi};
                
                colorNodeIds = tree.getchildren(1);
                data = {};
                colors = {};
                for colornode = 1:length(colorNodeIds)
                    colorData = struct();
                    colorData.intensity = [];
                    colorData.response = [];
                    colorData.responseSem = [];
                    currentStepColorNode = tree.get(colorNodeIds(colornode));
                    if ~strcmp(currentStepColorNode.splitParam, 'colorPattern2')
                        return
                    end
                    colors{colornode} = currentStepColorNode.splitValue;
                    rampnodes = tree.getchildren(colorNodeIds(colornode));

                    % get contrast from sample epoch

                    for ri = 1:length(rampnodes)
                        datanode = tree.get(rampnodes(ri));
                        contrastepoch = cellData.epochs(datanode.epochID(1));
                        fixedContrast = contrastepoch.get('contrast');
                        baseIntensity = contrastepoch.get('baseColor');
                        baseIntensity = baseIntensity(2);
                        varyingContrast = datanode.splitValue;
                        colorData.intensity(end+1) = ((varyingContrast - baseIntensity) / baseIntensity) / fixedContrast;
                        colorData.response(end+1) = datanode.(variableName).mean;
                        colorData.responseSem(end+1) = datanode.(variableName).SEM;
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
                    if vi == 1
%                         yyaxis left
                        dash = '-';
                        legends{end+1} = sprintf('%s varying, On', colors{ci});
                    else
%                         yyaxis right
                        dash = '--';
                        legends{end+1} = sprintf('%s varying, Off', colors{ci});
                    end
                    errorbar(d.intensity, d.response, d.responseSem, dash, 'Color', color, 'LineWidth', 3);
                    
                    hold on

                end
    %             legend(colors, 'Location', 'north')
            end
            hold off
            xlabel('(varying : fixed) contrast ratio')
%             legend(legends, 'Location','Best');
        end
    end
    
end


