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
                {'spotDiameter', 'annulusMode', 'NDF', 'RstarMean', params.ampModeParam, 'epochNum'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'sessionId', 'epochNum'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            sessionNodes = obj.getchildren(1);
            numSessions = length(sessionNodes);
            
            for i=1:numSessions %for each leaf node
                sessionNode = obj.get(sessionNodes(i));
                sessionId = sessionNode.splitValue;
                
                sessionEpochs = obj.getchildren(sessionNodes(i));
                epochData = cell(length(sessionEpochs), 1);
                
                for ei = 1:length(sessionEpochs)
                    curEpochNode = obj.get(sessionEpochs(ei));
                    
                    e = struct();
                    
                    epoch = cellData.epochs(curEpochNode.epochID);
                    e.parameters = epoch.attributes;
                    %                     e.parameters('baseIntensity1') = epoch.get('baseIntensity1');
                    %                     e.parameters('baseIntensity2') = epoch.get('baseIntensity2');
                    %                     e.parameters('colorPattern1') = epoch.get('colorPattern1');
                    %                     e.parameters('colorPattern2') = epoch.get('colorPattern2');
                    %                     e.parameters('contrast1') = epoch.get('contrast1');
                    %                     e.parameters('contrast2') = epoch.get('contrast2');
                    %                     if is
                    e.ignore = false;
                    
                    
                    %if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curEpochNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curEpochNode = mergeIntoNode(curEpochNode, outputStruct);
                    if strcmp(rootData.(rootData.ampModeParam), 'Whole cell')
                        outputStruct_WC = getEpochResponses_WC(cellData, curEpochNode.epochID, ...
                            'DeviceName', rootData.deviceName, 'LowPassFreq', 50);
                        outputStruct_WC = getEpochResponseStats(outputStruct_WC);
                        curEpochNode = mergeIntoNode(curEpochNode, outputStruct_WC);
                    end
                        
                    %end
                    %                     else %whole cell
                    %                         outputStruct = getEpochResponses_WC(cellData, curEpochNode.epochID, ...
                    %                             'DeviceName', rootData.deviceName);
                    %                         outputStruct = getEpochResponseStats(outputStruct);
                    %                         curEpochNode = mergeIntoNode(curEpochNode, outputStruct);
                    %                     end
                    
                    e.signal = epoch.getData('Amplifier_Ch1');
                    e.t = (1:numel(e.signal)) / 10000;
                    e.spikeFrames = epoch.getSpikes(rootData.deviceName);
                    e.spikeTimes = e.t(e.spikeFrames);
                    
                    e.response = curEpochNode;
                    
                    epochData{ei} = e;
                end
                
                sessionNode.epochData = epochData;
                
                
                obj = obj.set(sessionNodes(i), sessionNode);
            end
        end
        
    end
    
    
    methods(Static)
        function [pointData, interpolant] = analyzeData(epochData, variable)
            % collect all the epochs into a response table
            responseData = [];
            for ei = 1:length(epochData)
                e = epochData{ei};
                responseData(end+1,:) = [e.parameters('contrast1'), e.parameters('contrast2'), e.response.(variable)];
            end
            
            % combine responses into points
            [points, ~, indices] = unique(responseData(:,[1,2]), 'rows');
            for i = 1:size(points,1)
                m = mean(responseData(indices == i, 3));
                v = var(responseData(indices == i, 3));
                pointData(i,:) = [points(i,1), points(i,2), m, v/abs(m), sum(indices == i)];
            end
            
            % calculate map of current results
            if size(pointData, 1) >= 3
                c1 = pointData(:,1);
                c2 = pointData(:,2);
                r = pointData(:,3);
                interpolant = scatteredInterpolant(c1, c2, r, 'linear', 'none');
            end
            
        end
        
        
        function plot1_surfaceSpikesStiminterval(tree, ~)
            ColorIsoResponseAnalysis.plotIsoResponseSurface(tree, 'spikeCount_stimInterval_mean');
        end
        
        function plot2_surfaceSpikesAfterStiminterval(tree, ~)
            ColorIsoResponseAnalysis.plotIsoResponseSurface(tree, 'spikeCount_afterStim_mean');
        end
        
        
        function plot0_launchGui(tree, cellData)
            sessionNode = tree.get(1);
            if ~isfield(sessionNode,'epochData')
                return
            end
            epochData = sessionNode.epochData;
            sampleEpoch = epochData{1};
            
            try
                baseIntensity1 = sampleEpoch.parameters('baseIntensity1');
                baseIntensity2 = sampleEpoch.parameters('baseIntensity2');
            catch
                baseIntensity1 = sampleEpoch.parameters('meanLevel1');
                baseIntensity2 = sampleEpoch.parameters('meanLevel2');
                
            end
            colorPattern1 = sampleEpoch.parameters('colorPattern1');
            colorPattern2 = sampleEpoch.parameters('colorPattern2');
            
            if sampleEpoch.parameters('ampHoldSignal') == 0
                var = 'spikeCount_stimInterval_mean';
            else
                var = 'ONSET_avgTracePeak_value';
            end
            
            gui = ColorIsoResponseFigure('baseIntensity1', baseIntensity1, 'baseIntensity2', baseIntensity2, ...
                'colorNames', {colorPattern1, colorPattern2}, ...
                'epochData', epochData, 'variable', var);
            
        end
        
        function plotIsoResponseSurface(tree, variable)
            %             colorPattern1
            %             contrastRange1
            %             interpolant
            %             pointData
            %             plotRange2
            sessionNode = tree.get(1);
            if ~isfield(sessionNode,'epochData')
                return
            end
            epochData = sessionNode.epochData;
            sampleEpoch = epochData{1};
            baseIntensity1 = sampleEpoch.parameters('baseIntensity1');
            baseIntensity2 = sampleEpoch.parameters('baseIntensity2');
            colorPattern1 = sampleEpoch.parameters('colorPattern1');
            colorPattern2 = sampleEpoch.parameters('colorPattern2');
            
            %             modelCoefs = sessionNode.modelCoefs;
            %             modelCoefs_pValues = sessionNode.modelCoefs_pValues;
            
            [pointData, interpolant] = ColorIsoResponseAnalysis.analyzeData(epochData, variable);
            ax = gca();
            cla(ax)
            
            
            if ~isempty(pointData)
                if ~isempty(interpolant)
                    %                     try
                    c1p = linspace(min(pointData(:,1)), max(pointData(:,1)), 20);
                    c2p = linspace(min(pointData(:,2)), max(pointData(:,2)), 20);
                    [C1p, C2p] = meshgrid(c1p, c2p);
                    int = interpolant(C1p, C2p);
                    %                         f = fspecial('average');
                    %                         int = imfilter(int, f);
                    s = pcolor(ax, C1p, C2p, int);
                    shading(ax, 'interp');
                    set(s, 'PickableParts', 'none');
                    hold(ax, 'on');
                    contour(ax, C1p, C2p, int, 'k', 'ShowText','on', 'PickableParts', 'none')
                    %                     end
                end
                
                % observations
                for oi = 1:size(pointData,1)
                    siz = 80;
                    edg = 'k';
                    scatter(ax, pointData(oi,1), pointData(oi,2), siz, 'CData', pointData(oi,3), ...
                        'LineWidth', 1, 'MarkerEdgeColor', edg, 'MarkerFaceColor', 'flat')
                    hold(ax, 'on');
                end
            end
            
            % draw some nice on/off divider lines, and contrast boundary lines
            plotRange1 = xlim(ax);
            plotRange2 = ylim(ax);
            contrastRange1 = [-1, (1 / baseIntensity1) - 1];
            contrastRange2 = [-1, (1 / baseIntensity2) - 1];
            line(ax, [0,0], plotRange2, 'LineStyle', ':', 'Color', 'k', 'PickableParts', 'none');
            line(ax, plotRange1, [0,0], 'LineStyle', ':', 'Color', 'k', 'PickableParts', 'none');
            rectangle(ax, 'Position', [-1, -1, diff(contrastRange1), diff(contrastRange2)], 'EdgeColor', 'k', 'LineWidth', 1, 'PickableParts', 'none');
            
            xlabel(ax, colorPattern1);
            ylabel(ax, colorPattern2);
            xlim(ax, plotRange1 + [-.1, .1]);
            ylim(ax, plotRange2 + [-.1, .1]);
            % %             set(ax,'LooseInset',get(ax,'TightInset'))
            %             title(sprintf('LM fit coefs (P-val log10): UV: %.2g (%.1g) Green: %.2g (%.1g)', modelCoefs(3), log10(modelCoefs_pValues(3)), modelCoefs(2), log10(modelCoefs_pValues(2))), 'FontSize',14);
            hold(ax, 'off');
            
            
            % create fit surface for this data
            
        end
        
        
        
        function plot3_ramp_Spikes(tree, cellData)
            sessionNode = tree.get(1);
            if ~isfield(sessionNode,'epochData')
                return
            end
            epochData = sessionNode.epochData;
            sampleEpoch = epochData{1};
            baseIntensity1 = sampleEpoch.parameters('baseIntensity1');
            baseIntensity2 = sampleEpoch.parameters('baseIntensity2');
            colorPattern1 = sampleEpoch.parameters('colorPattern1');
            colorPattern2 = sampleEpoch.parameters('colorPattern2');
            
            
            variables = {'spikeCount_stimInterval_mean', 'spikeCount_afterStim_mean'};
            pointDatas = {};
            for i = 1:length(variables)
                [pointData, ~] = ColorIsoResponseAnalysis.analyzeData(epochData, variables{i});
                pointDatas{i} = pointData;
            end
            
            
            ax = gca();
            cla(ax)
            
            
            % get all contrasts to figure out the fixed value
            allRampEpochs = [];
            contrasts = [];
            
            for ei = 1:length(epochData)
                epoch = epochData{ei};
                if ~strcmp(epoch.parameters('stimulusMode'), 'ramp')
                    continue
                end
                allRampEpochs(end+1) = id;
                contrasts(end+1) = epoch.parameters('contrast1');
                contrasts(end+1) = epoch.parameters('contrast2');
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
                responses(ei,:) = responseByEpochId(id,:);
            end
            
            epochIsUvVarying = epochIsUvVarying == 1;
            
            ax = gca();
            hold(ax, 'on');
            % on
            errorbar(ax, contrastRatios(epochIsUvVarying), responses(epochIsUvVarying,1), zeros(sum(epochIsUvVarying),1), 'o', 'Color',[.3, 0, .9])
            plot(ax, contrastRatios(~epochIsUvVarying), responses(~epochIsUvVarying,1), 'o', 'Color',[0, .8, .1])
            
            % off
            plot(ax, contrastRatios(epochIsUvVarying), responses(epochIsUvVarying,2), 'o', 'Color',[.3, 0, .9])
            plot(ax, contrastRatios(~epochIsUvVarying), responses(~epochIsUvVarying,2), 'o', 'Color',[0, .8, .1])
            hold(ax, 'off');
            
        end
        
    end
    
end


%         function plot_ramp(tree, cellData, variables)
%             legends = {};
%             for vi = 1:length(variables)
%                 variableName = variables{vi};
%
%                 colorNodeIds = tree.getchildren(1);
%                 data = {};
%                 colors = {};
%                 for colornode = 1:length(colorNodeIds)
%                     colorData = struct();
%                     colorData.intensity = [];
%                     colorData.response = [];
%                     colorData.responseSem = [];
%                     currentStepColorNode = tree.get(colorNodeIds(colornode));
%                     if ~strcmp(currentStepColorNode.splitParam, 'colorPattern2')
%                         return
%                     end
%                     colors{colornode} = currentStepColorNode.splitValue;
%                     rampnodes = tree.getchildren(colorNodeIds(colornode));
%
%                     % get contrast from sample epoch
%
%                     for ri = 1:length(rampnodes)
%                         datanode = tree.get(rampnodes(ri));
%                         contrastepoch = cellData.epochs(datanode.epochID(1));
%                         fixedContrast = contrastepoch.get('contrast');
%                         baseIntensity = contrastepoch.get('baseColor');
%                         baseIntensity = baseIntensity(2);
%                         varyingContrast = datanode.splitValue;
%                         colorData.intensity(end+1) = ((varyingContrast - baseIntensity) / baseIntensity) / fixedContrast;
%                         colorData.response(end+1) = datanode.(variableName).mean;
%                         colorData.responseSem(end+1) = datanode.(variableName).SEM;
%                     end
%                     data{colornode} = colorData;
%                 end
%                 for ci = 1:length(colors)
%                     d = data{ci};
%                     switch colors{ci}
%                         case 'uv'
%                             color = [.3, 0, .9];
%                         case 'blue'
%                             color = [0, .5, 1];
%                         case 'green'
%                             color = [0, .8, .1];
%                     end
%                     if vi == 1
% %                         yyaxis left
%                         dash = '-';
%                         legends{end+1} = sprintf('%s varying, On', colors{ci});
%                     else
% %                         yyaxis right
%                         dash = '--';
%                         legends{end+1} = sprintf('%s varying, Off', colors{ci});
%                     end
%                     errorbar(d.intensity, d.response, d.responseSem, dash, 'Color', color, 'LineWidth', 3);
%
%                     hold on
%
%                 end
%     %             legend(colors, 'Location', 'north')
%             end
%             hold off
%             xlabel('(varying : fixed) contrast ratio')
% %             legend(legends, 'Location','Best');
%         end


