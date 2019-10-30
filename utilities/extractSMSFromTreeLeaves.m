function [] = extractSMSMetadataFromTreeLeaves(T, fname)
global CELL_DATA_FOLDER
%T is analysis tree

leafNodes = T.findleaves;
nLeaves = length(leafNodes);

lastNodeID = 0;
for i=1:nLeaves    
        curNodeID = T.Parent(leafNodes(i));
        curNode = T.get(curNodeID);
        
        
        if curNodeID ~= lastNodeID
            [cellName, rest] = strtok(curNode.name, ':');
            datasetName = strtok(deblank(rest), ':');
            datasetName = datasetName(2:end);

            %[psth_y, psth_x] = cellData.getPSTH(epochInd);
            [sms_maxResponse_spotSize] = curNode.spikeCount_stimInterval_grndBlSubt_spotSizeByMax;
            [sms_maxResponse_spikeCount]  = curNode.spikeCount_stimInterval.mean_c;
            [sms_suppression600] = curNode.spikeCount_stimInterval_grndBlSubt_SMSsupression1200;
            [sms_suppression1200] = curNode.spikeCount_stimInterval_grndBlSubt_SMSsupression1200;
            [sms_max_onoffratio] = curNode.max_ON_OFF_R;
            [sms_min_onoffratio] = curNode.min_ON_OFF_R; 
            [maxON_size] = curNode.maxON_size;
            [maxOFF_size] = curNode.maxOFF_size;
            
            s = struct;
            s.sms_maxResponse_spotSize = sms_maxResponse_spotSize;
            s.sms_maxResponse_spikeCount = sms_maxResponse_spikeCount;
            s.sms_suppression600 = sms_suppression600;
            s.sms_suppression1200 = sms_suppression1200;
            s.sms_max_onoffratio = sms_max_onoffratio;
            s.sms_min_onoffratio = sms_min_onoffratio;
            s.maxON_size = maxON_size;
            s.maxOFF_size = maxOFF_size;
            
            exportStructToHDF5(s, fname, [cellName '_' datasetName]);
        end
        lastNodeID = curNodeID;
end