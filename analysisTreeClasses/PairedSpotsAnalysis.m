classdef PairedSpotsAnalysis < AnalysisTree
    properties
        StartTime = 100
        EndTime = 200;
    end
    
    methods
        function obj = PairedSpotsAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
                        
            nameStr = [cellData.savedFileName ': ' dataSetName ': PairedSpotsAnalysis'];
            obj = obj.setName(nameStr);
            obj = obj.copyAnalysisParams(params);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'angle', 'isPair',  @(epoch)locationID(epoch)});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            for i=1:L
               curNode = obj.get(leafIDs(i));
               
               if cellData.epochs(curNode.epochID(1)).get('isPair')
                   curNode = getFromSampleEpoch(cellData, curNode, {'pairDistance', 'spot1ID', 'spot2ID'});
               end
                
                %obj.StartTime
                %obj.EndTime
               [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, 'Charge', ...
                   'DeviceName', rootData.deviceName, ...
                   'StartTime', obj.StartTime, ...
                   'EndTime', obj.EndTime);
               
                N = length(resp);
                curNode.resp = resp;
                curNode.respMean = mean(resp);
                curNode.respVar = var(resp);
                curNode.respSEM = std(resp)./sqrt(N);
                curNode.N = N;
                obj = obj.set(leafIDs(i), curNode);
            end
            

            %percolateUp to isPair level
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'respVar', 'respVar', ...
                'N', 'N', ...
                'pairDistance', 'pairDistance', ...
                'spot1ID', 'spot1ID', ...
                'spot2ID', 'spot2ID', ...
                'splitValue', 'locationID');
            
            pairNodes = getTreeLevel(obj, 'isPair', 1);
            L = length(pairNodes);
            for i=1:L
               curNodeData = obj.get(pairNodes(i));
               %making lookup table for spotID vs tree index of component
               %spots
               singleSpotsParent = setdiff(obj.getsiblings(pairNodes(i)), pairNodes(i));
               chInd = obj.getchildren(singleSpotsParent);
               Nspots = length(chInd);
               componentTable = zeros(Nspots, 2);
               for j=1:Nspots
                  componentTable(obj.get(chInd(j)).splitValue) = chInd(j); 
               end
               
               %calculate linear sum and NL index for each pair
               Npairs = length(curNodeData.pairDistance);
               for j=1:Npairs                   
                   curNodeData.spot1Mean(j) = obj.get(componentTable(curNodeData.spot1ID(j))).respMean;
                   curNodeData.spot2Mean(j) = obj.get(componentTable(curNodeData.spot2ID(j))).respMean;
                   curNodeData.spot1Var(j) = obj.get(componentTable(curNodeData.spot1ID(j))).respVar;
                   curNodeData.spot2Var(j) = obj.get(componentTable(curNodeData.spot2ID(j))).respVar;
                   curNodeData.spot1N(j) = obj.get(componentTable(curNodeData.spot1ID(j))).N;
                   curNodeData.spot2N(j) = obj.get(componentTable(curNodeData.spot2ID(j))).N;
               end
               curNodeData.linearSum = curNodeData.spot1Mean + curNodeData.spot2Mean;              
               curNodeData.NLI_num = curNodeData.respMean - curNodeData.linearSum;
               curNodeData.NLI_denom = sqrt((curNodeData.respVar ./ curNodeData.N) + (curNodeData.spot1Var ./ curNodeData.spot1N) + (curNodeData.spot2Var ./ curNodeData.spot2N));
               curNodeData.NLI = sign(curNodeData.respMean) .* curNodeData.NLI_num ./ curNodeData.NLI_denom;
               
               obj = obj.set(pairNodes(i), curNodeData);
                
            end
            
            obj = obj.percolateUp(pairNodes, ...
                'pairDistance', 'pairDistance', ...
                'NLI', 'NLI');
            
            angleNodes = getTreeLevel(obj, 'angle');
            obj = obj.percolateUp(angleNodes, ...
                'pairDistance', 'pairDistance', ...
                'NLI', 'NLI');
            
            %get variance across single spots
            singleNodes = getTreeLevel(obj, 'isPair', 0);
            obj = obj.percolateUp(singleNodes, ...
                'respMean', 'respMean', ...
                'respVar', 'respVar');
            
            obj = obj.percolateUp(angleNodes, ...
                'respMean', 'respMeanSingles', ...
                'respVar', 'respVarSingles');
            
            rootData = obj.get(1);
            rootData.CV_singles = std(rootData.respMeanSingles) ./ abs(mean(rootData.respMeanSingles));
            obj = obj.set(1, rootData);
            
            %get variance across pairs
            obj = obj.percolateUp(pairNodes, ...
                'respMean', 'respMeanPairs', ...
                'respVar', 'respVarPairs');
                        
            obj = obj.percolateUp(angleNodes, ...
               'respMeanPairs', 'respMeanPairs', ...
               'respVarPairs', 'respVarPairs');
            
            rootData = obj.get(1);
            rootData.CV_pairs = std(rootData.respMeanPairs) ./ abs(mean(rootData.respMeanPairs));            
            obj = obj.set(1, rootData);
            
        end
        
    end
    
    methods(Static)
        
        function plotData(node, cellData)
            rootData = node.get(1);
            scatter(rootData.pairDistance, rootData.NLI);
            xlabel('Pair distance (microns)');            
            ylabel('Nonlinearity index');   
        end
        
        %function plotMeanTraces(node, cellData)
        %    rootData = node.get(1);
                       
            
        %end
        
    end
    
end