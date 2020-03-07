function [] = extractSMSFromTreeLeaves(T)
%T is analysis tree

[fname, fpath] = uiputfile('*.h5','Select HDF5 file');

leafNodes = T.findleaves;
nLeaves = length(leafNodes);


cellNames = {};

baseline = linspace(0, 1200, 200);
all_ON = [];
all_OFF = [];

lastNodeID = 0;
for i=1:nLeaves    
        curNodeID = T.Parent(leafNodes(i));
        curNode = T.get(curNodeID);
        
        
        if curNodeID ~= lastNodeID
                [cellName, rest] = strtok(curNode.name, ':');
                if i > 1 && strcmp(cellName,cellNames{end,1})
                    continue
                end
                cellNames{end+1,1} = cellName;
                datasetName = strtok(deblank(rest), ':');
                datasetName = datasetName(2:end);

%                 curNode
                %[psth_y, psth_x] = cellData.getPSTH(epochInd);
                try
                    [sms_x] = curNode.spotSize;
                catch
                    continue
                end
                   
                [sms_y_on]  = curNode.spikeCount_stimInterval.mean_c;
                [sms_y_off] = curNode.spikeCount_afterStim.mean_c;

                y_on = interp1(sms_x, sms_y_on, baseline);
                y_off = interp1(sms_x, sms_y_off, baseline);


                all_ON(end+1, :) = y_on;
                all_OFF(end+1, :) = y_off;
                s = struct;
                s.sms_x = sms_x;
                s.sms_y_on = sms_y_on;
                s.sms_y_off = sms_y_off;
                %igorName = [cellName '_' datasetName];
                exportStructToHDF5(s, [fpath fname], cellName);
        end
        lastNodeID = curNodeID;
end


