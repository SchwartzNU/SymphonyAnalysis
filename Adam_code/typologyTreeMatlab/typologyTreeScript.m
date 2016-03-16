%generate typology tree script 1/20/15

tTree = typologyTree_remodel_1;

[nodeId, nodeCelltypeList, nodeConditions] = getSearchIndex(tTree);

conditionTree = singleFieldTree(tTree,'conditions');
celltypeTree = singleFieldTree(tTree,'cellTypeList');
idTree = singleFieldTree(tTree,'id');

conditionPath = getConditionsForTypes(tTree);

tTreePLOTS = typologyTreePlots(tTree, [] );
%tTreePLOTS = typologyTreePlots(tTree, [2221, 222212, 222222, 2222122 22221222] );

%extract n of cells from cumbersome tTreePLOTS, put in a function soon.
ns = ones(length(tTree.Node),1).*NaN;
for I = 1:length(tTree.Node)
    if iscell(tTreePLOTS{I}) & ~strcmp(tTreePLOTS{I},'ERROR: check parameter naming...')
        %first condition satisfied if not leaf
        curNcells = tTreePLOTS{I}{1}.numberOfCells; 
        ns(I) = sum(curNcells);
        
        %Try to fill in chidren that are leafs.
        childInd = tTree.getchildren(I);
        if isfield(tTreePLOTS{I}{1}, 'plotLegend')
            Legend = tTreePLOTS{I}{1}.plotLegend;
        else
            Legend = tTreePLOTS{I}{1}.histLegend;
        end;
        for ChI  = 1:2
            if tTree.isleaf(childInd(ChI))
                childCellType = nodeCelltypeList(childInd(ChI));
                legendIndex = getnameidx(Legend, childCellType);
                NcellsChild = curNcells(legendIndex);
                ns(childInd(ChI)) = NcellsChild;
            end;
        end;
    end;
end;
nTree = newFieldTree(tTree, ns);


% %Check overlap down the tree - individual cell names
% for I = 1:length(tTree.Node)
%     if ~tTree.isleaf(I)
%         childInd = tTree.getchildren(I);
%         for chI = 1:2
%             if ~tTree.isleaf(chI)
%                 parentNcells = tTreePLOTS{I}{1}.numberOfCells; 
%                 childNcells = tTreePLOTS{chI}{1}.numberOfCells; 
%             end;
%         end;
%         
%         
%         
%     end;
%     
% end;

