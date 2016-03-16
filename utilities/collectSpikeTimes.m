function [allCellNames, sp] = collectSpikeTimes(T)
%T is an alayais tree with a single leaf node of spike times for each cell
%we can make a more complex version in the future with options about
%exclusions, etc.

leafIDs = T.findleaves();
Ncells = length(leafIDs);
sp = cell(1,Ncells);
allCellNames = cell(1,Ncells);
for i=1:Ncells
    curNodeIndex = leafIDs(i);
    nodeData = T.get(curNodeIndex);
    mode = getMode(T, curNodeIndex);
    device = getDevice(T, curNodeIndex);    
    cellData_name = T.getCellName(curNodeIndex);
    allCellNames{i} = cellData_name;
    cellData = loadAndSyncCellData(cellData_name);
    if strcmp(mode, 'Cell attached')
        [PSTH, timeAxis_PSTH] = cellData.getPSTH(nodeData.epochID, [], device);
        L = length(nodeData.epochID);
        spikeTimes = cell(L,1);
        for e=1:L
            [spikeTimes{e}, timeAxis_spikes] = cellData.epochs(nodeData.epochID(e)).getSpikes(device);
        end
        sp{i} = spikeTimes;
    end
end
    


    
    
    
