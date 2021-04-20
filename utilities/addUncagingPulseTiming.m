function [] = addUncagingPulseTiming(cell_id)
cellData = loadAndSyncCellData(cell_id);
N = cellData.get('Nepochs');
for i=1:N
   shutterData = cellData.epochs(i).getData('ScanImageShutter');
   if ~isempty(shutterData)
        startTimes = getThresCross(shutterData, 0.5, 1);
        cellData.epochs(i).attributes('uncaging_start_times') = startTimes;
   end
end
saveAndSyncCellData(cellData);
