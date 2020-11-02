function T = updateCellTypesInTable(T)
Ncells = height(T);

for i=1:Ncells
   i
   curCell = T{i,'CellID'};
   curCell = curCell{1}
   cellData = loadAndSyncCellData(curCell);
   T{i,'CellType'} = {cellData.cellType};     
end