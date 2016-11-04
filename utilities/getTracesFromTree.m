function [goodNodesData, goodNodes] = getTracesFromTree(analysisTree, analysisName)
%Adam 1/7/16
% Good only for a tree containing a single cell?
N_nodes = length(analysisTree.Node);
goodNodes=[];
goodNodesData = [];
for nod = 1:N_nodes %run over relevant datasets
%     if nod == 493
%       keyboard;
%     end;
    curNode = analysisTree.Node{nod};
    if isfield(curNode,'class')
        if strcmp(curNode.class,analysisName)
            goodNodes = [goodNodes, nod];
            if isfield(curNode,'ampMode')
                parentStruct = struct;
                parentStruct.ampMode = analysisTree.Node{nod}.ampMode;
                parentStruct.name = analysisTree.Node{nod}.name;
                
%                 % % future: put any parameters that want by passing their names into function
%                 if strcmp(parentStruct.ampMode,'Cell attached')
%                     parentStruct.spikeCount_stimAfter200ms = analysisTree.Node{nod}.spikeCount_stimAfter200ms.mean;
%                     parentStruct.spikeCount_stimToEnd = analysisTree.Node{nod}.spikeCount_stimToEnd.mean;
%                     parentStruct.spikeCount_stimInterval = analysisTree.Node{nod}.spikeCount_stimInterval.mean;
%                     parentStruct.ONSET_FRhalfMaxSusLatency = analysisTree.Node{nod}.ONSET_FRhalfMaxSusLatency.value;
%                     parentStruct.spikeCount_stimInterval_baselineSubtracted =...
%                         analysisTree.Node{nod}.spikeCount_stimInterval_baselineSubtracted.mean;
%                     parentStruct.stimToEnd_avgTrace_latencyToT25 = [];
%                     parentStruct.stimToEnd_respIntervalT25 = [];
%                     parentStruct.stimToEnd_avgTrace_latencyToT25 = [];
%                     parentStruct.stimToEnd_respIntervalT25 = [];
%                 else
%                     parentStruct.spikeCount_stimAfter200ms = [];
%                     parentStruct.spikeCount_stimToEnd = [];
%                     parentStruct.spikeCount_stimInterval = [];
%                     parentStruct.ONSET_FRhalfMaxSusLatency = [];
%                     parentStruct.spikeCount_stimInterval_baselineSubtracted = [];
%                     parentStruct.stimToEnd_avgTrace_latencyToT25 = analysisTree.Node{nod}.stimToEnd_avgTrace_latencyToT25.value;
%                     parentStruct.stimToEnd_respIntervalT25 = analysisTree.Node{nod}.stimToEnd_respIntervalT25.value;
%                     parentStruct.stimToEnd_avgTrace_latencyToT25 = analysisTree.Node{nod}.stimToEnd_avgTrace_latencyToT25.value;
%                     parentStruct.stimToEnd_respIntervalT25 = analysisTree.Node{nod}.stimToEnd_respIntervalT25.value;
%                 end;
                % % %
                childId = analysisTree.getchildren(nod);
                
                datasetName = strsplit(parentStruct.name,': ');
                cellName = datasetName{1};
                load([cellName, '.mat']);
                %load('103015Ac10.mat'); %hack if cell name messed up in cellData
                childData = [];
                for ch = 1:length(childId) %run over leafs (single splitValues) 
                    childStruct = struct;
                    childStruct.splitValue = analysisTree.Node{childId(ch)}.splitValue;
                    eps =  analysisTree.Node{childId(ch)}.epochID;
                    
                    if strcmp(parentStruct.ampMode,'Cell attached')   %CA
                        [psth, xvals] = cellData.getPSTH(eps, 10);
                        childStruct.psth = psth;
                        childStruct.x_psth = xvals;
                    elseif strcmp(parentStruct.ampMode,'Whole cell')   %WC
                        [meanData, xvals] = cellData.getPSTH(eps, 10);
                        childStruct.meanData = meanData;
                        childStruct.x_meanData = xvals;
                    end;
                    for ep = 1:length(eps) %run over epochs of leaf
                        [dataTrace, x_raw] = cellData.epochs(eps(ep)).getData; 
                        if ep == 1
                            dataMatrix = zeros(length(eps),length(dataTrace)); 
                        end;
                        dataMatrix(ep,:) = dataTrace;
                    end;
                    childStruct.x_rawData = x_raw;
                    childStruct.rawDataMatrix = dataMatrix;
                    childData = [childData, childStruct];
                end;
                parentStruct.childData = childData;
                goodNodesData = [goodNodesData,parentStruct];
            end; %if isfield(curNode,'ampMode')
        end;
    end;
end;