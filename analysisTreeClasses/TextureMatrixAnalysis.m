classdef TextureMatrixAnalysis < AnalysisTree
    %re-written 10/21/15 by Adam
    properties
        StartTime = 0;
        EndTime = 0;
        xAxisName = 'pixelBlur';
        seedFieldName = 'randSeed';
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
            
            
            if cellData.get('symphonyVersion') == 2
                %Symphony2
                if ~isnan(cellData.epochs(dataSet(1)).get('textureScale'))
                    %Stimulus preliminary v.1
                    obj.xAxisName = 'textureScale';  
                    obj.seedFieldName = 'randomSeed';
                else
                    obj.xAxisName = 'halfMaxScale';  
                    obj.seedFieldName = 'randomSeed';
                end;
            else
                %Symphony1
                obj.xAxisName = 'pixelBlur';
                obj.seedFieldName = 'randSeed';
            end;
            


            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'maskSize', params.ampModeParam});
            acrossSeedTree = obj.buildCellTree(1, cellData, dataSet, {obj.xAxisName, obj.seedFieldName});
            acrossBlurTree = obj.buildCellTree(1, cellData, dataSet, {obj.seedFieldName, obj.xAxisName});
            
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
            
            
            randSeedLeaves = getTreeLevel(obj, obj.seedFieldName);
            randSeedLeaves = intersect(randSeedLeaves,leafIDs);
            pixelBlurLeaves = getTreeLevel(obj, obj.xAxisName);
            pixelBlurLeaves = intersect(pixelBlurLeaves,leafIDs);
            
            % percolate up randSeedLeaves subtree
            obj = obj.percolateUp(randSeedLeaves, ...
                'splitValue', obj.seedFieldName);
            
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(randSeedLeaves, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(randSeedLeaves, singleValParamList, singleValParamList);
            obj = obj.percolateUp(randSeedLeaves, collectedParamList, collectedParamList);
            
            % percolate up pixelBlurLeaves subtree
            obj = obj.percolateUp(pixelBlurLeaves, ...
                'splitValue', obj.xAxisName);
            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(pixelBlurLeaves, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(pixelBlurLeaves, singleValParamList, singleValParamList);
            obj = obj.percolateUp(pixelBlurLeaves, collectedParamList, collectedParamList);
            
            %to add more here
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {obj.seedFieldName,obj.xAxisName};
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
            %                 'splitValue', xAxisName);
            
            obj = obj.percolateUp(pixelBlurParents, ...
                'splitValue', obj.xAxisName);
            obj = obj.percolateUp(pixelBlurParents, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(pixelBlurParents, singleValParamList, singleValParamList);
            obj = obj.percolateUp(pixelBlurParents, collectedParamList, collectedParamList);
            
            obj = obj.percolateUp(randSeedParents, ...
                'splitValue', obj.seedFieldName);
            obj = obj.percolateUp(randSeedParents, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(randSeedParents, singleValParamList, singleValParamList);
            obj = obj.percolateUp(randSeedParents, collectedParamList, collectedParamList);
            
            %Texture scale x-axis; fitting. Adam 4/13/17; 
            %Next - adapt to Symphony2 data too 
            blurRootDataID = childrenByValue(obj, 1, 'name', 'Across seed tree');
            blurRootData = obj.get(blurRootDataID);
            %Convert blur sigma pixels > microns> "texture spatial scale" (see Mani and Schwartz 2017)
            %from "blurToTrueSpatialScale2017.m"  
%             pa = [-0.0001403,-0.02534,5.799,-1.387];
%             pb = [-5.049e-05,-0.01521,5.799,-2.312]; 
%             

            %From adam's analysis 4/27/17, "textureGeneration_halfMax.m"
            %"sigmaVsHalfMaxScale_pixels_SUMMARY.mat"
            fitPixelsToPixels = [6.39024e-06,-0.000578271,-0.0364984,7.62814,0.0201946];
            
            
            whichRig = blurRootData.cellName(7);     
            
            if strcmp(obj.xAxisName, 'pixelBlur')
                %Symphony1

                
                blurSigma = blurRootData.pixelBlur; %in pixels
                if strcmp(whichRig, 'A')
                    micPerPix = 1.38;
                else
                    %Rig B standard projector!
                    micPerPix = 2.3;
                end;
                %micronBlur = pixelBlur*micPerPix;
                %blurRootData.micronBlur = micronBlur;
                %halfMaxScale = micPerPix*polyval(fitPixelsToPixels, (1/micPerPix).*micronBlur);
                halfMaxScale = micPerPix*polyval(fitPixelsToPixels, blurSigma);
                %Don't use pixel blur (sigma) < 0.6 pixels.
                % values below that give 1/2 max at about the same scale
                % "0 blur" in old textures were no blur, step power spectrum at scale = sqrt(2) pixels
                halfMaxScale(blurSigma < 0.6) = micPerPix*polyval(fitPixelsToPixels, 0.6);
                halfMaxScale(blurSigma == 0) = micPerPix*sqrt(2);
                blurRootData.blurSigma = blurSigma; %(pixels)
                blurRootData.halfMaxScale = halfMaxScale; %(microns)
                %given in microns per cycle
            elseif strcmp(obj.xAxisName, 'textureScale')
                %Symphony2 stimulus version 1 - x axis is "textureScale" (v.1) = 2 sigma in microns
                leafIDs = obj.findleaves();
                epochIDs = obj.Node{leafIDs(1)}.epochID;
                resScaleFactor = cellData.epochs(epochIDs(1)).get('resScaleFactor'); 
                
                
                if strcmp(whichRig, 'A')
                    micPerPix = 1.38*resScaleFactor;
                else
                    %Rig B standard projector!
                    micPerPix = 2.3*resScaleFactor;
                end;
                blurSigma = (blurRootData.textureScale/2)/micPerPix; %in pixels
                halfMaxScale = micPerPix*polyval(fitPixelsToPixels, blurSigma);
                halfMaxScale(blurSigma < 0.6) = micPerPix*polyval(fitPixelsToPixels, 0.6);
                halfMaxScale(blurSigma == 0) = micPerPix*sqrt(2);
                blurRootData.blurSigma = blurSigma; %(pixels)
                blurRootData.halfMaxScale = halfMaxScale; %(microns)
            else
                %Symphony2 - x axis is blurSigma (v.2)
                %Don't use pixel blur (sigma) < 0.6 pixels
                %effective micPerPix depends on "reScaleFactor" in stimulus code
                
                %Do nothing! Symphony 2 should have already!
            end;
      
            blurRootData = addLinearInterp(blurRootData);  
            obj = obj.set(blurRootDataID, blurRootData);
            %%%%%%%%%%%%%%%            
            
        end
        
    end
    
    methods(Static)
        
        function plotAllData(node, cellData)
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
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
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren)      %i=[1,4]
                curNode = node.get(seedChildren(i));
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
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren)      %i=[1,4]
                curNode = node.get(seedChildren(i));
                
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
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
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
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
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
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
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
            blurParent = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurParent.halfMaxScale;
            %            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                curNode = node.get(seedChildren(i));
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
            xvals = blurRootData.halfMaxScale;
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
            xvals = blurRootData.halfMaxScale;
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
%             xvals = blurRootData.pixelBlur;
            xvals = blurRootData.halfMaxScale;
            yMean = blurRootData.spikeCount_stimInterval_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr);
%             xlabel('Pixel blur');
            xlabel('Texture half max scale');
            ylabel('Spike count gblSubt');
            
            hold('on');
            xfit = min(xvals):0.5:max(xvals);
            %yfit = Heq(blurRootData.beta, xfit);
            yfit = feval(blurRootData.fitresult, xfit);
            plot(xfit,yfit);
            plot(blurRootData.crossing,feval(blurRootData.fitresult,blurRootData.crossing),'o')         
            hold('off');
        end
        
        function plotMeanData_stimIntFRmax20_gblSubt(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
%             xvals = blurRootData.pixelBlur;
            xvals = blurRootData.halfMaxScale;
            yMean = blurRootData.stimInt20_FRmax.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr);
%             xlabel('Pixel blur');
            xlabel('Texture half max scale');
            ylabel('FR max');
         end
        
        
        
        
        function plotMeanData_spkStimInt_gblSubtNORM(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
%             xvals = blurRootData.pixelBlur;
            xvals = blurRootData.halfMaxScale;
            yMean = blurRootData.spikeCount_stimInterval_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimInterval_grndBlSubt.SEM_c;
            M = max(abs(yMean));
            yMean = yMean./M;
            yMeanErr = yMeanErr./M;
            errorbar(xvals, yMean, yMeanErr,'r');
%             xlabel('Pixel blur');
            xlabel('Texture half max scale');
            ylabel('Spike count gblSubt (norm)');
            hold('off');
        end
        
        function plotMeanData_stimToEnd_gblSubtNORM(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            xvals = blurRootData.halfMaxScale;
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
            xvals = blurRootData.halfMaxScale;
            yMean = blurRootData.spikeCount_stimToEnd_grndBlSubt.mean_c;
            yMeanErr = blurRootData.spikeCount_stimToEnd_grndBlSubt.SEM_c;
            errorbar(xvals, yMean, yMeanErr,'r');
            xlabel('Pixel blur');
            ylabel('Spike count stimToEnd gblSubt');
            hold('off');
        end
        
    end
    
end