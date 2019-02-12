classdef SplitFieldAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = SplitFieldAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': SplitFieldAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'barAngle', 'blackSide', @(epoch)barPosition2D(epoch)});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);

            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                channelPresenceCheck = cellData.epochs(curNode.epochID).getData(rootData.deviceName);
                if isempty(channelPresenceCheck)
                    continue
                end                
%                 if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
%                 else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
%                 end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'position');
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            %fnames = fnames{1};
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
         
            %add lists to angleNodes
            bsNodes = getTreeLevel(obj,'blackSide');
            for i=1:length(bsNodes)
                curData = obj.get(bsNodes(i));
                curData.byEpochParamList = byEpochParamList;
                curData.singleValParamList = singleValParamList;
                curData.collectedParamList = collectedParamList;
                curData.stimParameterList = {'position'};
                obj = obj.set(bsNodes(i), curData);
            end
            
%             %to add more here
%             rootData = obj.get(1);
%             rootData.byEpochParamList = byEpochParamList;
%             rootData.singleValParamList = singleValParamList;
%             rootData.collectedParamList = collectedParamList;
%             rootData.stimParameterList = {'position'};
%             obj = obj.set(1, rootData);
            % % %
            
        end
        
    end    
    
    methods(Static)
        function plot_positionVsONSETspikes(node, cellData)
            rootData = node.get(1);
            xvals = rootData.position;
            yField = rootData.ONSETspikes;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('position');
            ylabel(['ONSETspikes (' yField.units ')']);
        end
        
        function plot_positionVsSpikeCount_stimInterval(node, cellData)
            rootData = node.get(1);
            xvals = rootData.position;
            yField = rootData.spikeCount_stimInterval;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('position');
            ylabel(['spikeCount_stimInterval (' yField.units ')']);
        end          

        function plot_positionVsSpikeCount_stimTo200ms(node, cellData)
            rootData = node.get(1);
            xvals = rootData.position;
            yField = rootData.spikeCount_stimTo200ms;
            if strcmp(yField.units, 's')
                yvals = yField.median_c;
            else
                yvals = yField.mean_c;
            end
            errs = yField.SEM;
            errorbar(xvals, yvals, errs);
            xlabel('position');
            ylabel(['spikeCount_stimTo200ms (' yField.units ')']);
        end        
        
        function plot0_twoSided_positionVsSpikeCount_stimInterval(node, cellData)
            childNodes = node.getchildren(1);
            
            centerPoint = 0;
            flipx = 0;
            
            for ni = 1:2
                rootData = node.get(childNodes(ni));
                xvals = rootData.position;
                if ni == 1
                    xvals = xvals - centerPoint;
                else
                    xvals = fliplr(xvals + centerPoint);
                end
                if flipx
                    xvals = -xvals;
                end
                yField = rootData.spikeCount_stimInterval;
                if strcmp(yField.units, 's')
                    yvals = yField.median_c;
                else
                    yvals = yField.mean_c;
                end
                errs = yField.SEM;
                errorbar(xvals, yvals, errs);
                hold on
                peaks(ni) = max(yvals);
            end
            xlabel('position');
            ylabel(['spikeCount_stimInterval (' yField.units ')']);
            legend('On negative','On positive')
            title(sprintf('peak1: %g, peak2: %g', peaks(1), peaks(2)));
        end  
        
        function plot1_twoSided_positionVsSpikeCount_stimTo200ms(node, cellData)
            childNodes = node.getchildren(1);
            for ni = 1:2
                rootData = node.get(childNodes(ni));
                xvals = rootData.position;
                yField = rootData.spikeCount_stimTo200ms;
                if strcmp(yField.units, 's')
                    yvals = yField.median_c;
                else
                    yvals = yField.mean_c;
                end
                errs = yField.SEM;
                errorbar(xvals, yvals, errs);
                hold on
            end
            xlabel('position');
            ylabel(['spikeCount_stimTo200ms (' yField.units ')']);
        end  
        
    
    
        function plot2_twoSided_positionVsONSET_charge400ms(node, cellData)
            childNodes = node.getchildren(1);
            for ni = 1:2
                rootData = node.get(childNodes(ni));
                xvals = rootData.position;
                yField = rootData.ONSET_charge400ms;
                if strcmp(yField.units, 's')
                    yvals = yField.median_c;
                else
                    yvals = yField.mean_c;
                end
                errs = yField.SEM;
                errorbar(xvals, yvals, errs);
                hold on
                peaks(ni) = max(yvals);
                
            end
            xlabel('position');
            ylabel(['ONSET_charge400ms (' yField.units ')']);
            title(sprintf('peak1: %g, peak2: %g', peaks(1), peaks(2)));
            
        end      
    end
end
