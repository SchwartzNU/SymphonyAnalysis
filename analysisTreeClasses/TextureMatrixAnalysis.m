classdef TextureMatrixAnalysis < AnalysisTree
    %re-written 10/21/15 by Adam
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = TextureMatrixAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': TextureMatrixAnalysis'];
            obj = obj.setName(nameStr);
            obj = obj.copyAnalysisParams(params);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam});
            acrossSeedTree = obj.buildCellTree(1, cellData, dataSet, {'pixelBlur', 'randSeed'});
            acrossBlurTree = obj.buildCellTree(1, cellData, dataSet, {'randSeed', 'pixelBlur'});
            
            nodeData = acrossSeedTree.get(1);
            nodeData.name = 'Across seed tree';
            acrossSeedTree = acrossSeedTree.set(1, nodeData);
            nodeData = acrossBlurTree.get(1);
            nodeData.name = 'Across blur tree';
            acrossBlurTree = acrossBlurTree.set(1, nodeData);
            
            obj = obj.graft(1, acrossSeedTree);
            obj = obj.graft(1, acrossBlurTree);
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);  %for grandBaseline subt.
            
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName,'StartTime', obj.StartTime, 'EndTime', obj.EndTime, ...
                        'FitPSTH', 0);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c; %for grandBaseline subt.
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    %'ZeroCrossingPeaks', crossingParam);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            %grand baseline subtraction
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                %baseline subtraction
                
                grandBaselineMean = mean(baseline);
                for i=1:L %for each leaf node
                    curNode = obj.get(leafIDs(i));
                    tempStruct.spikeCount_stimInterval_grndBlSubt = curNode.spikeCount_stimInterval;
                    tempStruct.spikeCount_stimInterval_grndBlSubt.value = curNode.spikeCount_stimInterval.value - grandBaselineMean; %assumes 1 sec stim interval
                    tempStruct.spikeCount_stimInterval_grndBlSubt.type = 'byEpoch';
                    
                    tempStruct.spikeCount_stimToEnd_grndBlSubt = curNode.spikeCount_stimToEnd;
                    tempStruct.spikeCount_stimToEnd_grndBlSubt.value = curNode.spikeCount_stimToEnd.value - grandBaselineMean*2; %assumes 2 sec stim to end
                    tempStruct.spikeCount_stimToEnd_grndBlSubt.type = 'byEpoch';
                    
                    tempStruct = getEpochResponseStats(tempStruct);
                    curNode = mergeIntoNode(curNode, tempStruct);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            
            randSeedLeaves = getTreeLevel(obj, 'randSeed');
            randSeedLeaves = intersect(randSeedLeaves,leafIDs);
            pixelBlurLeaves = getTreeLevel(obj, 'pixelBlur');
            pixelBlurLeaves = intersect(pixelBlurLeaves,leafIDs);
            
            % percolate up randSeedLeaves subtree
            obj = obj.percolateUp(randSeedLeaves, ...
                'splitValue', 'randSeed');
            
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(randSeedLeaves, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(randSeedLeaves, singleValParamList, singleValParamList);
            obj = obj.percolateUp(randSeedLeaves, collectedParamList, collectedParamList);
            
            % percolate up pixelBlurLeaves subtree
            obj = obj.percolateUp(pixelBlurLeaves, ...
                'splitValue', 'pixelBlur');
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(pixelBlurLeaves, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(pixelBlurLeaves, singleValParamList, singleValParamList);
            obj = obj.percolateUp(pixelBlurLeaves, collectedParamList, collectedParamList);
            
            %to add more here
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'randSeed','curInnerDiameter'};
            obj = obj.set(1, rootData);
            % % %
            
            randSeedParents = obj.getchildren(childrenByValue(obj, 1, 'name', 'Across blur tree'));
            pixelBlurParents = obj.getchildren(childrenByValue(obj, 1, 'name', 'Across seed tree'));
            
            %             %these 2 are just 2 copies of the same data!
            %             obj = obj.percolateUp(randSeedParents, ...
            %                 'respMean_blur', 'respMean_blur_all', ...
            %                 'respVar_blur', 'respVar_blur_all');
            %
            %             obj = obj.percolateUp(pixelBlurParents, ...
            %                 'respMean_seed', 'respMean_seed_all', ...
            %                 'respVar_seed', 'respVar_seed_all');
            
            % %             %these 2 are just 2 copies of the same data!
            %             obj = obj.percolateUp(randSeedParents, byEpochParamList, byEpochParamList);
            %             obj = obj.percolateUp(randSeedParents, singleValParamList, singleValParamList);
            %             obj = obj.percolateUp(randSeedParents, collectedParamList, collectedParamList);
            %
            %             obj = obj.percolateUp(pixelBlurParents, byEpochParamList, byEpochParamList);
            %             obj = obj.percolateUp(pixelBlurParents, singleValParamList, singleValParamList);
            %             obj = obj.percolateUp(pixelBlurParents, collectedParamList, collectedParamList);
            %
            
            
            for i=1:length(randSeedParents)
                nodeData = obj.get(randSeedParents(i));
                %                 nodeData.var_ratio = var(nodeData.respMean_blur) ./ mean(nodeData.respVar_blur);
                %                 nodeData.SNR = std(nodeData.respMean_blur) ./ mean(nodeData.respMean_blur);
                %                 nodeData.meanVals = mean(nodeData.respMean_blur);
                nodeData = vectorsToScalarMeans(nodeData);
                obj = obj.set(randSeedParents(i), nodeData);
            end
            
            for i=1:length(pixelBlurParents)
                nodeData = obj.get(pixelBlurParents(i));
                %                 nodeData.var_ratio = var(nodeData.respMean_blur) ./ mean(nodeData.respVar_blur);
                %                 nodeData.SNR = std(nodeData.respMean_blur) ./ mean(nodeData.respMean_blur);
                %                 nodeData.meanVals = mean(nodeData.respMean_blur);
                nodeData = vectorsToScalarMeans(nodeData);
                obj = obj.set(pixelBlurParents(i), nodeData);
            end
            
            %             obj = obj.percolateUp(randSeedParents, ...
            %                 'var_ratio', 'var_ratio', ...
            %                 'SNR', 'SNR', ...
            %                 'meanVals', 'meanVals', ...
            %                 'splitValue', 'randSeed');
            %
            %             obj = obj.percolateUp(pixelBlurParents, ...
            %                 'var_ratio', 'var_ratio', ...
            %                 'SNR', 'SNR', ...
            %                 'meanVals', 'meanVals', ...
            %                 'splitValue', 'pixelBlur');
            
            obj = obj.percolateUp(pixelBlurParents, ...
                'splitValue', 'pixelBlur');
            obj = obj.percolateUp(pixelBlurParents, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(pixelBlurParents, singleValParamList, singleValParamList);
            obj = obj.percolateUp(pixelBlurParents, collectedParamList, collectedParamList);
            
            obj = obj.percolateUp(randSeedParents, ...
                'splitValue', 'randSeed');
            obj = obj.percolateUp(randSeedParents, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(randSeedParents, singleValParamList, singleValParamList);
            obj = obj.percolateUp(randSeedParents, collectedParamList, collectedParamList);
            
        end
        
    end
    
    methods(Static)
        
        function plotAllData(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                %                 yvals = curNode.overEpochs_ONSETspikes.mean_c;
                %                 yerrs = curNode.overEpochs_ONSETspikes.SEM;
                yvals = curNode.overEpochs_spikeCount_stimInterval_baselineSubtracted.mean_c;
                yerrs = curNode.overEpochs_spikeCount_stimInterval_baselineSubtracted.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            %             yMean = blurRootData.ONSETspikes.mean_c;`
            %             yMeanErr = blurRootData.ONSETspikes.SEM_c;
            yMean = blurRootData.spikeCount_stimInterval_baselineSubtracted.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_baselineSubtracted.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        function plotAllData_gbl(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren)      %i=[1,4]
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                %                 yvals = curNode.overEpochs_ONSETspikes.mean_c;
                %                 yerrs = curNode.overEpochs_ONSETspikes.SEM;
                yvals = curNode.overEpochs_spikeCount_stimInterval_grndBlSubt.mean_c;
                yerrs = curNode.overEpochs_spikeCount_stimInterval_grndBlSubt.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');  %,'LineStyle','none'
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            %             yMean = blurRootData.ONSETspikes.mean_c;`
            %             yMeanErr = blurRootData.ONSETspikes.SEM_c;
            yMean = blurRootData.spikeCount_stimInterval_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        function plotAllData_stimToEnd_gbl(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren)      %i=[1,4]
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                %                 yvals = curNode.overEpochs_ONSETspikes.mean_c;
                %                 yerrs = curNode.overEpochs_ONSETspikes.SEM;
                yvals = curNode.overEpochs_spikeCount_stimToEnd_grndBlSubt.mean_c;
                yerrs = curNode.overEpochs_spikeCount_stimToEnd_grndBlSubt.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');  %,'LineStyle','none'
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            %             yMean = blurRootData.ONSETspikes.mean_c;`
            %             yMeanErr = blurRootData.ONSETspikes.SEM_c;
            yMean = blurRootData.spikeCount_stimToEnd_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimToEnd_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count stimToEnd');
            hold('off');
        end
        
        function plotAllData_ONSETspikes(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                yvals = curNode.overEpochs_ONSETspikes.mean_c;
                yerrs = curNode.overEpochs_ONSETspikes.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            yMean = blurRootData.ONSETspikes.mean_c;
            yMeanErr = blurRootData.ONSETspikes.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        function plotAllData_OFFspikes_blSubt(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                yvals = curNode.overEpochs_spikeCount_tailInterval_baselineSubtracted.mean_c;
                yerrs = curNode.overEpochs_spikeCount_tailInterval_baselineSubtracted.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            yMean = blurRootData.spikeCount_tailInterval_baselineSubtracted.mean_c;
            yMeanErr = blurRootData.spikeCount_tailInterval_baselineSubtracted.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        function plotAllData_ONSET_FRmax(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                yvals = curNode.overEpochs_ONSET_FRmax.value;
                %yerrs = curNode.overEpochs_ONSET_FRmax.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                plot(xvals, yvals,'b','marker','o','LineStyle','none');
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            yMean = blurRootData.ONSET_FRmax.mean_c;
            yMeanErr = blurRootData.ONSET_FRmax.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        function plotAllData_ONSETpeakInstantaneousFR(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
                xvals = curNode.pixelBlur;
                yvals = curNode.overEpochs_ONSETpeakInstantaneousFR.mean_c;
                yerrs = curNode.overEpochs_ONSETpeakInstantaneousFR.SEM;
                %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
                errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');
                %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                %                     [c(mod(i,5)+1) 'o-']);
                hold('on');
            end
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            yMean = blurRootData.ONSETpeakInstantaneousFR.mean_c;
            yMeanErr = blurRootData.ONSETpeakInstantaneousFR.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        
        %         function plotAllData_ONSETspikesGrandBLsubt(node, cellData)
        %         COMPLETE
        %             seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
        % %            c = ['b', 'r', 'g', 'k', 'm'];
        %             for i=1:length(seedChildren);
        %                 curNode = node.get(seedChildren(i));
        %                 xvals = curNode.pixelBlur;
        %                 yvals = curNode.overEpochs_ONSETpeakInstantaneousFR.mean_c;
        %                 yerrs = curNode.overEpochs_ONSETpeakInstantaneousFR.SEM;
        %                 %plot(xvals, yvals, [c(mod(i,5)+1) 'o']);
        %                 errorbar(xvals, yvals, yerrs,'b','marker','o','LineStyle','none');
        % %                 errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
        % %                     [c(mod(i,5)+1) 'o-']);
        %                 hold('on');
        %             end
        %             blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
        %             yMean = blurRootData.ONSETpeakInstantaneousFR.mean_c;
        %             yMeanErr = blurRootData.ONSETpeakInstantaneousFR.SEM_c;
        %             errorbar(xvals, yMean, yMeanErr,'r');
        %             xlabel('Pixel blur');
        %             ylabel('Spike count (norm)');
        %             hold('off');
        %         end
        
        function plotMeanDataNorm(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.pixelBlur;
            yMean = blurRootData.spikeCount_stimInterval_baselineSubtracted.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_baselineSubtracted.SEM_c;
            M = max(yMean);
            yMean = yMean./M;
            yMeanErr = yMeanErr./M;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        function plotMeanDataNormOFF(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.pixelBlur;
            yMean = blurRootData.spikeCount_tailInterval_baselineSubtracted.mean_c;
            yMeanErr = blurRootData.spikeCount_tailInterval_baselineSubtracted.SEM_c;
            M = max(yMean);
            yMean = yMean./M;
            yMeanErr = yMeanErr./M;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end
        
        %         function plotMeanData_spkStimInt_gblSubt(node, cellData)
        %             rootData = node.get(1);
        %             xvals = rootData.curInnerDiameter;
        %             yField = rootData.spikeCount_stimInterval_grndBlSubt;
        %             if strcmp(yField.units, 's')
        %                 yvals = yField.median_c;
        %             else
        %                 yvals = yField.mean_c;
        %             end
        %             errs = yField.SEM;
        %             errorbar(xvals, yvals, errs);
        %             xlabel('inner diameter');
        %             ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
        %         end
        
        function plotMeanData_spkStimInt_gblSubt(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.pixelBlur;
            yMean = blurRootData.spikeCount_stimInterval_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count gblSubt');
            hold('off');
        end
        
        %         function plotMeanData_spkStimInt_gblSubtNORM(node, cellData)
        %             rootData = node.get(1);
        %             xvals = rootData.curInnerDiameter;
        %             yField = rootData.spikeCount_stimInterval_grndBlSubt;
        %             if strcmp(yField.units, 's')
        %                 yvals = yField.median_c;
        %             else
        %                 yvals = yField.mean_c;
        %             end
        %             errs = yField.SEM;
        %             M = max(abs(yvals));
        %             yvals = yvals./M;
        %             errs = errs./M;
        %             errorbar(xvals, yvals, errs);
        %             xlabel('inner diameter');
        %             ylabel(['spikeCount_stimInterval_granBaselineSubtracted (' yField.units ')']);
        %         end
        
        function plotMeanData_spkStimInt_gblSubtNORM(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.pixelBlur;
            yMean = blurRootData.spikeCount_stimInterval_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_grndBlSubt.SEM_c;
            M = max(abs(yMean));
            yMean = yMean./M;
            yMeanErr = yMeanErr./M;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count gblSubt (norm)');
            hold('off');
        end
        
        function plotMeanData_stimToEnd_gblSubtNORM(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.pixelBlur;
            yMean = blurRootData.spikeCount_stimToEnd_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimToEnd_grndBlSubt.SEM_c;
            M = max(abs(yMean));
            yMean = yMean./M;
            yMeanErr = yMeanErr./M;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count stimToEnd gblSubt (norm)');
            hold('off');
        end
        
        function plotMeanData_stimToEnd_gblSubt(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.pixelBlur;
            yMean = blurRootData.spikeCount_stimToEnd_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimToEnd_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count stimToEnd gblSubt (norm)');
            hold('off');
        end
        
    end
    
end