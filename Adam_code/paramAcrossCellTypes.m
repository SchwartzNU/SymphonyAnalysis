function paramAcrossCellTypes(analysisTree, paramName, paramRange, userLabel) 
%runs over a tree generated by LabDataGUI analyzing multiple cell types;
%Adam 11/13/14 based on 11/23/14

pathname = '/Users/adammani/Documents/analysis/Adam Matlab analysis/121814/mat files/';
filename = ['multiCellType_',paramName,'_',userLabel];
fullfilename = [pathname, filename,'.mat'];
% textfilename = [pathname, filename,'.txt'];

cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    curCellType(strfind(curCellType,' ')) = '';
    curCellType(strfind(curCellType,'/')) = '';
    curCellType(strfind(curCellType,'-')) = '';
    
    curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
    [cellNames, paramForCells] = paramAcrossCells(curCellTypeTree, paramName); 
    
    varName = [curCellType, paramName];
    varNameCellTypes = [curCellType,'', 'CellNames'];
    eval([varName,' = paramForCells;']);
    eval([varNameCellTypes, ' = cellNames;']);
    
    %save; overwrites existing!!
    if cellTypeInd == 1
        save(fullfilename, varName, varNameCellTypes);
    else
        save(fullfilename, varName, varNameCellTypes,'-append');
    end;    
    
%     %cell array for igor
%     eval(['forIgor{cellTypeInd} = ',varName]);
    

end; 

% %text file for igor;
% dlmwrite(textfilename, forIgor);

%plot
plotSingleAxisStacked(filename, paramName, paramRange);
    
end
