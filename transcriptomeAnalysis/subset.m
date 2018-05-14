function [cellInd_ofSubset, geneInd_ofSubset, D_ofSubset, sortedCellTypes, sorted_D_ofSubset] = subset(D, cellTypes, cellIDs, geneNames, gene, selection, makeGraph)


% Can be used to simply identify the indices of certain cell types and/or
% genes, a full expression matrix for those subsets, OR a figure.

%Returns: 
%   targetInd: a vector of cell indices within vector 'cellTypes' that 
%       either match a given character search 'selection', OR a 
%       manually-chosen subset of cells, OR all cells
%   geneInd: a vector of gene indices within 'geneNames' that match a
%       given search 'gene' OR all genes
%   geneCounts: the expression matrix of the above genes in the above cells
cellInd_ofSubset = [];

if isempty(selection) % If empty, return everything
    cellInd_ofSubset = 1:length(cellTypes);
    cellTypes_ofSubset = cellTypes(cellInd_ofSubset);
elseif isnumeric(selection(1)) % If numeric, return those indices
    cellInd_ofSubset = selection;
    cellTypes_ofSubset = cellTypes(cellInd_ofSubset);
    %disp([num2str(length(cellInd_ofSubset)) ' cells selected.']);
else % must be either a string or string vector, so let's search for it!
    selectedType = selection;
    cellInd_ofSubset = find(contains(cellTypes, selectedType, 'IgnoreCase', true));
    cellTypes_ofSubset = cellTypes(cellInd_ofSubset);
    disp([num2str(length(cellInd_ofSubset)) ' cells of type ' selectedType ', including:']);
    disp([unique(cellTypes(cellInd_ofSubset))]);
end

if isempty(gene) % If empty, return everything
    geneInd_ofSubset = (1:length(geneNames))';
elseif isnumeric(gene) % If numeric, return those indices
    geneInd_ofSubset = gene;
else % must be either a string or string vector, so let's search for it!
    geneInd_ofSubset = find(contains(geneNames, gene, 'IgnoreCase', true));
    disp([num2str(length(geneInd_ofSubset)) ' genes containing ' gene ', including:']);
    disp([geneNames(geneInd_ofSubset)]);
end

% if ~isempty(directionPref)
%     dirPref_ofSubset = directionPref(cellInd_ofSubset);
%     for i=1:length(dirPref_ofSubset)
%         if ~strcmp(dirPref_ofSubset{i}, '-')
%             cellTypes_ofSubset{i} = [cellTypes_ofSubset{i} ':' dirPref_ofSubset{i}];
%         end
%     end
% end

if ~isempty(cellIDs)
    cellIDs_ofSubset = cellIDs(cellInd_ofSubset);
    for i=1:length(cellIDs_ofSubset)
        if length(cellIDs_ofSubset{i}) == 9
            cellTypes_ofSubset{i} = [cellTypes_ofSubset{i} '   [ ' cellIDs_ofSubset{i} ']'];
        else
            cellTypes_ofSubset{i} = [cellTypes_ofSubset{i} '   [' cellIDs_ofSubset{i} ']'];
        end
    end
end

[sortedCellTypes, sortedIndices] = sort(cellTypes_ofSubset);

D_ofSubset = D(geneInd_ofSubset,cellInd_ofSubset);
sorted_D_ofSubset = D_ofSubset(:,sortedIndices);

if makeGraph == 1
    figure;
    
    %%% Is the data already log transformed?
    %imagesc(log(D_ofSubset));
    imagesc(sorted_D_ofSubset);

    
%     if ~isempty(directionPref)
%         dirPref_ofSubset = directionPref(cellInd_ofSubset);
%         sorted_dirPref_ofSubset = dirPref_ofSubset(sortedIndices);
%         
%         for i=1:length(sorted_dirPref_ofSubset)
%             if ~strcmp(sorted_dirPref_ofSubset{i}, '-')
%                 sortedCellTypes{i} = [sortedCellTypes{i} ':' sorted_dirPref_ofSubset{i}];
%             end
%         end
%     end
%             
%     if ~isempty(cellIDs)
%         cellIDs_ofSubset = cellIDs(cellInd_ofSubset);
%         sorted_cellIDs_ofSubset = cellIDs_ofSubset(sortedIndices);
%         for i=1:length(sortedCellTypes)
%             if length(sorted_cellIDs_ofSubset{i}) == 9
%                 sortedCellTypes{i} = [sortedCellTypes{i} '   [ ' sorted_cellIDs_ofSubset{i} ']'];
%             else
%                 sortedCellTypes{i} = [sortedCellTypes{i} '   [' sorted_cellIDs_ofSubset{i} ']'];
%         end
%     end
    
    %Axis Setup
    ax=gca;
    set(ax, 'TickDir','out',...
        'yTickLabel',geneNames(geneInd_ofSubset),...
        'ytick',(1:size(D_ofSubset,1)),...
        'xTickLabel',(sortedCellTypes),...
        'xtick',[1:length(cellInd_ofSubset)],...
        'xTickLabelRotation',90,...
        'FontName','FixedWidth');
else
end

end