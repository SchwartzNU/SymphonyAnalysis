function celltypeConditionPath = getConditionsForTypes(tTree)
%For each cell type get conditions leading to its classification
%Adam 1/14/15

cellTypeList0 =  {
    'ON alpha';
    'OFF transient alpha';
    'OFF sustained alpha';
    'ON high speed sensitive';
    'OFF transient high speed sensitive';
    'ON-OFF DS sustained';
    'ON-OFF DS transient';
    'ON DS sustained';
    'ON sustained non-alpha';
    'ON sustained ODB';
    'ON transient LSDS';
    'LED';
    'ON-OFF size selector';
    'ON transient OFF sustained';
    'Suppressed by contrast';
    'ON delayed';
    'ON OS';
    'OFF OS';
    'JAM-B';
    'Large bursty'};

[~, nodeCelltypeList, nodeConditions] = getSearchIndex(tTree);

celltypeConditionPath = cell(length(cellTypeList0),2);
for cellType0ind = 1:length(cellTypeList0)
    celltypeNodeIdx = multiOcurrGetIdx(nodeCelltypeList,cellTypeList0(cellType0ind));
    
    condPath = cell(length(celltypeNodeIdx),1);
    for splitInd = 1:length(celltypeNodeIdx)
          curNodeInd = celltypeNodeIdx(splitInd);
          cPath = nodeConditions(curNodeInd);
          while tTree.getparent(curNodeInd) ~= 1  
            curNodeInd = tTree.getparent(curNodeInd);
            cPath = [nodeConditions(curNodeInd); cPath];
          end;
          condPath{splitInd} = cPath;
   
    end;
    celltypeConditionPath{cellType0ind, 1} = cellTypeList0(cellType0ind);
    celltypeConditionPath{cellType0ind, 2} = condPath;
    
end;

end
