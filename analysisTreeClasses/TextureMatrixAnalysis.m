classdef TextureMatrixAnalysis < AnalysisTree
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
            allBaselineSpikes = [];
            for i=1:L
                curNode = obj.get(leafIDs(i));
                [baselineSpikes, respUnits, baselineLen] = getEpochResponses(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName, ...
                    'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                [spikes, respUnits, intervalLen] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                    'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                N = length(spikes);
                curNode.N = N;                
                allBaselineSpikes = [allBaselineSpikes, baselineSpikes];
                curNode.spikes = spikes;
                obj = obj.set(leafIDs(i), curNode);
            end
            %subtract baseline
            baselineMean = mean(allBaselineSpikes);
            for i=1:L
                curNode = obj.get(leafIDs(i));
                curNode.resp = curNode.spikes - (baselineMean * intervalLen/baselineLen);
                curNode.respMean = mean(curNode.resp);
                curNode.respVar = var(curNode.resp);
                curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                obj = obj.set(leafIDs(i), curNode);
            end
            
            
            randSeedLeaves = getTreeLevel(obj, 'randSeed');
            pixelBlurLeaves = getTreeLevel(obj, 'pixelBlur');
            
            obj = obj.percolateUp(randSeedLeaves, ...
                'respMean', 'respMean_seed', ...
                'respSEM', 'respSEM_seed', ...
                'respVar', 'respVar_seed', ...
                'N', 'N_seed');
            
            obj = obj.percolateUp(pixelBlurLeaves, ...
                'respMean', 'respMean_blur', ...
                'respSEM', 'respSEM_blur', ...
                'respVar', 'respVar_blur', ...
                'N', 'N_blur', ...
                'splitValue', 'pixelBlurVals');
            
            randSeedParents = obj.getchildren(childrenByValue(obj, 1, 'name', 'Across blur tree'));
            pixelBlurParents = obj.getchildren(childrenByValue(obj, 1, 'name', 'Across seed tree'));
            
            %these 2 are just 2 copies of the same data!
            obj = obj.percolateUp(randSeedParents, ...
                'respMean_blur', 'respMean_blur_all', ...
                'respVar_blur', 'respVar_blur_all');
            
            obj = obj.percolateUp(pixelBlurParents, ...
                'respMean_seed', 'respMean_seed_all', ...
                'respVar_seed', 'respVar_seed_all');
            
            
            for i=1:length(randSeedParents)
               nodeData = obj.get(randSeedParents(i));
               nodeData.var_ratio = var(nodeData.respMean_blur) ./ mean(nodeData.respVar_blur);
               nodeData.SNR = std(nodeData.respMean_blur) ./ mean(nodeData.respMean_blur); 
               nodeData.meanVals = mean(nodeData.respMean_blur); 
               obj = obj.set(randSeedParents(i), nodeData);
            end
            
            for i=1:length(pixelBlurParents)
               nodeData = obj.get(pixelBlurParents(i));
               nodeData.var_ratio = var(nodeData.respMean_seed) ./ mean(nodeData.respVar_seed);   
               nodeData.SNR = std(nodeData.respMean_seed) ./ mean(nodeData.respMean_seed);  
               nodeData.meanVals = mean(nodeData.respMean_seed);  
               obj = obj.set(pixelBlurParents(i), nodeData);
            end
            
            obj = obj.percolateUp(randSeedParents, ...
                'var_ratio', 'var_ratio', ...
                'SNR', 'SNR', ...
                'meanVals', 'meanVals', ...
                'splitValue', 'randSeed');
            
            obj = obj.percolateUp(pixelBlurParents, ...
                'var_ratio', 'var_ratio', ...
                'SNR', 'SNR', ...
                'meanVals', 'meanVals', ...
                'splitValue', 'pixelBlur');
                        
        end
        
    end
    
    methods(Static)
        
        function plotPixelBlurDataVarRatio(node, cellData)
            seedRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            
            plot(seedRootData.pixelBlur, seedRootData.var_ratio, 'o-');
            xlabel('Pixel blur');
            ylabel('Variance ratio');
            
        end
        
        function plotRandSeedDataVarRatio(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across blur tree'));
            
            scatter(blurRootData.randSeed, blurRootData.var_ratio);
            xlabel('Random seed');
            ylabel('Variance ratio');

        end
        
         function plotPixelBlurDataSNR(node, cellData)
            seedRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            
            plot(seedRootData.pixelBlur, seedRootData.SNR, 'o-');
            xlabel('Pixel blur');
            ylabel('SNR');
            
        end
        
        function plotRandSeedDataSNR(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across blur tree'));
            
            scatter(blurRootData.randSeed, blurRootData.SNR);
            xlabel('Random seed');
            ylabel('SNR');

        end
        
        function plotPixelBlurDataMeans(node, cellData)
            seedRootData = node.get(childrenByValue(node, 1, 'name', 'Across seed tree'));
            
            plot(seedRootData.pixelBlur, seedRootData.meanVals, 'o-');
            xlabel('Pixel blur');
            ylabel('MeanResp');
            
        end
        
        function plotRandSeedDataMeans(node, cellData)
            blurRootData = node.get(childrenByValue(node, 1, 'name', 'Across blur tree'));
            
            scatter(blurRootData.randSeed, blurRootData.meanVals);
            xlabel('Random seed');
            ylabel('MeanResp');

        end
        
        function plotAllData(node, cellData)            
            seedChildren = node.getchildren(childrenByValue(node, 1, 'name', 'Across blur tree'));
            c = ['b', 'r', 'g', 'k', 'm'];
            for i=1:length(seedChildren);
                errorbar(node.get(seedChildren(i)).pixelBlurVals, node.get(seedChildren(i)).respMean_blur, node.get(seedChildren(i)).respSEM_blur, ...
                    [c(mod(i,5)+1) 'o-']);
                hold('on');
            end            
            xlabel('Pixel blur');
            ylabel('Spike count (norm)');
            hold('off');
        end

    end
    
end