classdef LightStepAnalysisTEMP < AnalysisTree
    properties
        %put a dialog box for preferences in the LabDataGUI!
        StartTime = 0;
        EndTime = 0;
        %respType = 'Charge';        
    end
    
    methods
        function obj = LightStepAnalysisTEMP(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': LightStepAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'spotSize', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'RstarMean'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);

            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponsesTEMP(cellData, curNode.epochID, ... 
                    'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);                          
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                else %whole cell
                    disp('Whole-cell not yet implemented');                    
                    return                    
                end    
                                 
                obj = obj.set(leafIDs(i), curNode);
            end
            
        end
        
    end
    
    methods(Static)
        
%         function plotBlistPdf(node, cellData)
%             rootData = node.get(1);
%             if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
%                 baselineISI = [];
%                 baselineISI2 = [];
%                 for ind = 1:length(node.Node{2}.baselineISIepochs)
%                     ISI = node.Node{2}.baselineISIepochs{ind};
%                     ISI2 = ISI(1:end-1) + ISI(2:end);
%                     baselineISI = [baselineISI, ISI];
%                     baselineISI2 = [baselineISI2, ISI2];
%                 end;     
%                 X = (0.002:0.004:max(baselineISI2));
%                 H = hist(baselineISI2, X);
%                 bar(X,H./sum(H));
%                 ylim([0,1]);
%             end;
%         end;
        
%         function plotONresponseISI(node, cellData)
%             rootData = node.get(1);
%             if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
%                 ONenhancedISI = [];
%                 ONenhancedISI2 = [];
%                 for ind = 1:length(node.Node{2}.ONenhancedISIepochs)
%                     ISI = node.Node{2}.ONenhancedISIepochs{ind};
%                     ISI2 = ISI(1:end-1) + ISI(2:end);
%                     ONenhancedISI = [ONenhancedISI, ISI];
%                     ONenhancedISI2 = [ONenhancedISI2, ISI2];
%                 end;    
%                 X = (0.002:0.004:max(ONenhancedISI2));
%                 H = hist(ONenhancedISI2, X);
%                 bar(X,H./sum(H));
%                 ylim([0,1]);
%             end;
%         end;
        
%         function plotOFFresponseISI(node, cellData)
%             rootData = node.get(1);
%             if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
%                 OFFenhancedISI = [];
%                 OFFenhancedISI2 = [];
%                 for ind = 1:length(node.Node{2}.OFFenhancedISIepochs)
%                     ISI = node.Node{2}.OFFenhancedISIepochs{ind};
%                     ISI2 = ISI(1:end-1) + ISI(2:end);
%                     OFFenhancedISI = [OFFenhancedISI, ISI];
%                     OFFenhancedISI2 = [OFFenhancedISI2, ISI2];
%                 end;    
%                 X = (0.002:0.004:max(OFFenhancedISI2));
%                 H = hist(OFFenhancedISI2, X);
%                 bar(X,H./sum(H));
%                 ylim([0,1]);
%                 title(['3 spikes < blistQshort:' num2str( length(find(OFFenhancedISI2< node.Node{2}.blistQshort))/length(OFFenhancedISI2) )]);
%             end;
%         end;
        
        function plotMeanTrace(node, cellData)
            rootData = node.get(1);
            epochInd = node.get(2).epochID;
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                cellData.plotPSTH(epochInd, 10, rootData.deviceName);
%                 hold on
%                 firingStart = node.get(2).meanONlatency;
%                 firingEnd = firingStart + node.get(2).meanONenhancedDuration;
%                 plot([firingStart firingEnd], [0 0]);
%                 hold off
            else
                cellData.plotMeanData(epochInd, true, [], rootData.deviceName);
            end            
            title(['ON latency: ',num2str(node.get(2).meanONlatency),' ste: ',num2str(node.get(2).steONlatency)]);
        end  

        function plotEpochData(node, cellData, device, epochIndex)
            nodeData = node.get(1);
            cellData.epochs(nodeData.epochID(epochIndex)).plotData(device);
            title(['Epoch # ' num2str(nodeData.epochID(epochIndex)) ': ' num2str(epochIndex) ' of ' num2str(length(nodeData.epochID))]);
            if strcmp(device, 'Amplifier_Ch1')
                spikesField = 'spikes_ch1';
            else
                spikesField = 'spikes_ch2';
            end
            spikeTimes = cellData.epochs(nodeData.epochID(epochIndex)).get(spikesField);
            if ~isnan(spikeTimes)
                [data, xvals] = cellData.epochs(nodeData.epochID(epochIndex)).getData(device);
                hold('on');
                plot(xvals(spikeTimes), data(spikeTimes), 'rx');
                hold('off');
            end
            
            ONendTime = cellData.epochs(nodeData.epochID(epochIndex)).get('stimTime')*1E-3; %s
            ONstartTime = 0; 
            if isfield(nodeData, 'ONSETlatency')
               %draw lines here
               hold on
               firingStart = node.get(1).ONSETlatency.value(epochIndex)+ONstartTime;
               firingEnd = firingStart + node.get(1).ONSETrespDuration.value(epochIndex);
               burstBound = firingStart + node.get(1).ONSETburstDuration.value(epochIndex); 
               upperLim = max(data)+50;
               lowerLim = min(data)-50;
               plot([firingStart firingStart], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
               plot([firingEnd firingEnd], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
               plot([burstBound burstBound], [upperLim lowerLim], 'LineStyle','--');
               hold off
            end;
            if isfield(nodeData, 'OFFSETlatency')
               %draw lines here
               hold on
               firingStart = node.get(1).OFFSETlatency.value(epochIndex)+ONendTime;
               firingEnd = firingStart + node.get(1).OFFSETrespDuration.value(epochIndex);
               burstBound = firingStart + node.get(1).OFFSETburstDuration.value(epochIndex);
               upperLim = max(data)+50;
               lowerLim = min(data)-50;
               plot([firingStart firingStart], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
               plot([firingEnd firingEnd], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
               plot([burstBound burstBound], [upperLim lowerLim], 'LineStyle','--');
               hold off
            end
        
        end

%         function plotEpochData(node, cellData, device, epochIndex)
%             disp('Class specific plotEpochData');
%             nodeData = node.get(1);
%             epoch1overISI  =nodeData.epoch1overISI;
%             
%             
%             curEpoch = cellData.epochs(nodeData.epochID(epochIndex));
%             [~, xvals, ~] = curEpoch.getData(device);
%             sampleRate = curEpoch.get('sampleRate');
%             spikeTimes = curEpoch.getSpikes(device);
%             [~, stimStart] = min(abs(xvals)); %closest point to zero
%             stimStart = stimStart(1);
%             spikeTimes = spikeTimes - stimStart;
%             spikeTimes = spikeTimes / sampleRate;
% 
%             if ~isnan(spikeTimes)
%                 ISIrate = [0 epoch1overISI{epochIndex}];
%                 %ISImean2 = (ISIrate(1:end-1) + ISIrate(2:end))./2;
%                 %diffMean2 = [0 0 0 (ISImean2(3:end) - ISImean2(1:end-2))];
%                 %diffISIrate = [0 ISIrate(2:end) - ISIrate(1:end-1)];
%                 ISIratio = [0 ISIrate(2:end)./ISIrate(1:end-1)];
%                 
%                 plot(spikeTimes, ISIrate); 
%                 hold on;
%                 plot(spikeTimes, ISIratio, 'r');
%                 hold off;
%                 xlim([-0.5, 2]);
%             end
%             
%             ONendTime = cellData.epochs(nodeData.epochID(epochIndex)).get('stimTime')*1E-3; %s
%             ONstartTime = 0; 
%             if isfield(nodeData, 'ONlatency')
%                %draw lines here
%                hold on
%                firingStart = node.get(1).ONlatency(epochIndex)+ONstartTime;
%                firingEnd = firingStart + node.get(1).ONenhancedDuration(epochIndex);
% %               burstBound = firingStart + node.get(1).ONburstDuration(epochIndex); 
%                upperLim = max(epoch1overISI{epochIndex})+10;
%                lowerLim = min(epoch1overISI{epochIndex})-10;
%                plot([firingStart firingStart], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
%                plot([firingEnd firingEnd], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
% %               plot([burstBound burstBound], [upperLim lowerLim], 'LineStyle','--');
%                hold off
%             end;
% %             if isfield(nodeData, 'OFFlatency')
% %                %draw lines here
% %                hold on
% %                firingStart = node.get(1).OFFlatency(epochIndex)+ONendTime; 
% %                firingEnd = firingStart + node.get(1).OFFenhancedDuration(epochIndex);
% %                burstBound = firingStart + node.get(1).OFFburstDuration(epochIndex); 
% %                upperLim = max(epoch1overISI{epochIndex})+10;
% %                lowerLim = min(epoch1overISI{epochIndex})-10;
% %                plot([firingStart firingStart], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
% %                plot([firingEnd firingEnd], [upperLim lowerLim], 'LineStyle','--','Color',[1 0 0]);
% %                plot([burstBound burstBound], [upperLim lowerLim], 'LineStyle','--');
% %                hold off
% %             end
%         end
            
            
        end
end