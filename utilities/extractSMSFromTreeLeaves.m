function [] = extractSMSFromTreeLeaves(T, fname)
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
            [sms_x] = curNode.spotSize;
            [sms_y_on]  = curNode.spikeCount_stimInterval.mean_c;
            [sms_y_off] = curNode.spikeCount_afterStim.mean_c;
            s = struct;
            s.sms_x = sms_x;
            s.sms_y_on = sms_y_on;
            s.sms_y_off = sms_y_off;
            igorName = [cellName '_' datasetName];
            exportStructToHDF5(s, fname, igorName);
        end
        lastNodeID = curNodeID;
end