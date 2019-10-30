function [ FB_all ] = extractFBMetadataFromTreeLeaves(T)
global CELL_DATA_FOLDER
%T is analysis tree

leafNodes = T.findleaves;
nLeaves = length(leafNodes);

FB_all = {};
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
            FB_all(dataRow,:) = { cellType, cellName,...
                curNode.dumbOSI,...
                curNode.spikeCount_stimInterval_OSI,...
                curNode.spikeCount_stimInterval_OSang,...
                curNode.ONSETtransPeak_OSI,...
                curNode.ONSETtransPeak_OSang,...
                max(curNode.spikeRate_stimInterval.mean_c),...
                max(curNode.spikeCount_stimInterval.mean_c),...
                min(curNode.spikeCount_stimInterval.mean_c),...
                curNode.nullResp_spikes};
%             s = struct;
%             s.meta_sms_maxResponse_spotSize = sms_maxResponse_spotSize;
%             s.sms_maxResponse_spikeCount = sms_maxResponse_spikeCount;
%             s.sms_suppression600 = sms_suppression600;
%             s.sms_suppression1200 = sms_suppression1200;
%             exportStructToHDF5(s, fname, [cellName '_' datasetName]);
%             
            dataRow = dataRow+1;
        end
        lastNodeID = curNodeID;
end

FB_all = cell2table(FB_all);

FB_all.Properties.VariableNames{1} = 'cellType';
FB_all.Properties.VariableNames{2} = 'cellName';
FB_all.Properties.VariableNames{3} = 'dumbOSI';
FB_all.Properties.VariableNames{4} = 'OSI';
FB_all.Properties.VariableNames{5} = 'OSangle';
FB_all.Properties.VariableNames{6} = 'OSI_transient';
FB_all.Properties.VariableNames{7} = 'OS_transientAngle';
FB_all.Properties.VariableNames{8} = 'peakResp_avgHz';
FB_all.Properties.VariableNames{9} = 'peakResp_avgSpikes';
FB_all.Properties.VariableNames{10} = 'lowResp_avgSpikes';
FB_all.Properties.VariableNames{11} = 'nullResp_avgSpikes';
