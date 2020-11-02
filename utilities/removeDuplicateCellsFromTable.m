function Tnew = removeDuplicateCellsFromTable(T)

allCells = unique(T.CellID);
L = length(allCells);

for i=1:L
   ind = find(strcmp(T.CellID, allCells{i}));
   if length(ind) == 1
      Tnew(i,:) = T(ind,:); 
   else
      T(ind,:)
      indToKeep = input('Which dataset do you want to keep (line #)?');
      Tnew(i,:) = T(ind(indToKeep),:); 
   end  
end