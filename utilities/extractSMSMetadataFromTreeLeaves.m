function [ dataArray ] = extractSMSMetadataFromTreeLeaves(T)
global CELL_DATA_FOLDER
%T is analysis tree

leafNodes = T.findleaves;
nLeaves = length(leafNodes);

dataArray = {};
dataRow = 1;

lastNodeID = 0;
for i=1:nLeaves    
        curNodeID = T.Parent(leafNodes(i));
        curNode = T.get(curNodeID);
        parent = T.get(T.Parent(T.Parent(T.Parent((leafNodes(i))))));
        cellType = parent.name;
        
        if curNodeID ~= lastNodeID
            [cellName, rest] = strtok(curNode.name, ':');
            datasetName = strtok(deblank(rest), ':');
            datasetName = datasetName(2:end);

            %[psth_y, psth_x] = cellData.getPSTH(epochInd);
            % curNode.spikeCount_stimInterval_grndBlSubt_SMSsupression600 curNode.spikeCount_stimInterval_grndBlSubt_SMSsupression1200

            dataArray(dataRow,:) = { cellType, cellName,...
                curNode.maximizing_spotSize,...
                curNode.spikeCount_stimInterval_grndBlSubt_spotSizeByMax,...
                curNode.spikeCount_stimInterval_grndBlSubt_SMSsupression600,...
                curNode.spikeCount_stimInterval_grndBlSubt_SMSsupression1200,...
                curNode.max_ON_OFF_R,...
                curNode.maxON_R_size,...
                curNode.maxON,...
                curNode.maxON_size,...
                curNode.ON_OFF_R_maxON,...
                curNode.min_ON_OFF_R,...
                curNode.maxOFF_R_size,...
                curNode.maxOFF,...
                curNode.maxOFF_size,...
                curNode.spikeCount_afterStim_grndBlSubt_spotSizeByMax,...
                curNode.spikeCount_afterStim_grndBlSubt_SMSsupression600,...
                curNode.spikeCount_afterStim_grndBlSubt_SMSsupression1200,...
                curNode.ON_OFF_R_maxOFF};
%             
            dataRow = dataRow+1;
        end
        lastNodeID = curNodeID;
        
end

dataArray = cell2table(dataArray);

dataArray.Properties.VariableNames{1} = 'cellType';
dataArray.Properties.VariableNames{2} = 'cellName';
dataArray.Properties.VariableNames{3} = 'maxONResponse_spotSize';
dataArray.Properties.VariableNames{4} = 'maxONResponse_spikesBaselineSubtracted';
dataArray.Properties.VariableNames{5} = 'ON_suppression_by600um';
dataArray.Properties.VariableNames{6} = 'ON_suppression_by1200um';
dataArray.Properties.VariableNames{7} = 'maxONOFFRatio';
dataArray.Properties.VariableNames{8} = 'maxONOFFRatio_spotSize';
dataArray.Properties.VariableNames{9} = 'maxONresponse_spikes';
dataArray.Properties.VariableNames{10} = 'maxONresponse_spotSize';
dataArray.Properties.VariableNames{11} = 'maxONresponse_ONOFFRatio';
dataArray.Properties.VariableNames{12} = 'minONOFFRatio';
dataArray.Properties.VariableNames{13} = 'minONOFFRatio_spotSize';
dataArray.Properties.VariableNames{14} = 'maxOFFresponse_spikes';
dataArray.Properties.VariableNames{15} = 'maxOFFresponse_spotSize';
dataArray.Properties.VariableNames{16} = 'maxOFFResponse_spikesBaselineSubtracted';
dataArray.Properties.VariableNames{17} = 'OFF_suppression_by600um';
dataArray.Properties.VariableNames{18} = 'OFF_suppression_by1200um';
dataArray.Properties.VariableNames{19} = 'maxOFFresponse_ONOFFRatio';



