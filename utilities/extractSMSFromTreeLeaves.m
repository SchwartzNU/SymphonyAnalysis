function [] = extractSMSFromTreeLeaves(T, fname)
global ANALYSIS_FOLDER


%T is analysis tree
if nargin < 2
    [fname, fpath] = uiputfile('*.h5','Select HDF5 file');
else
    fpath = [ANALYSIS_FOLDER 'igorh5' filesep 'SMS'];    
    temp = what(fpath);
    fpath = temp.path;
end

leafNodes = T.findleaves;
nLeaves = length(leafNodes);


cellNames = {};

lastNodeID = 0;

tempName = [fpath filesep fname '.h5'];
if exist(tempName, 'file') %delete old file
    delete(tempName);
end

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

                s = struct;
                s.sms_x = sms_x;
                s.sms_y_on = sms_y_on;
                s.sms_y_off = sms_y_off;
                %igorName = [cellName '_' datasetName];
                exportStructToHDF5(s, [fpath filesep fname '.h5'], cellName);
        end
        lastNodeID = curNodeID;
end


