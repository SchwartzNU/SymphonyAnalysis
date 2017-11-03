function [cellInd_ofSubset, geneInd_ofSubset, D_ofSubset] = subset(D, cellTypes, geneNames, gene, selection, makeGraph)


% Can be used to simply identify the indices of certain cell types and/or
% genes, a full expression matrix for those subsets, OR a figure.

%Returns: 
%   targetInd: a vector of cell indices within vector 'cellTypes' that 
%       either match a given character search 'selection', OR a 
%       manually-chosen subset of cells, OR all cells
%   geneInd: a vector of gene indices within 'geneNames' that match a
%       given search 'gene' OR all genes
%   geneCounts: the expression matrix of the above genes in the above cells


if ischar(selection) % If a string, return all cells whose type contains that string
    selectedType = selection;
    cellInd_ofSubset = find(contains(cellTypes, selectedType));
    disp([num2str(length(cellInd_ofSubset)) ' cells of type ' selectedType ', including:']);
    disp([unique(cellTypes(cellInd_ofSubset))]);
elseif isempty(selection); % If empty, return everything
    cellInd_ofSubset = 1:length(cellTypes);
else isvector(selection) % If a vector, return the vector
    cellInd_ofSubset = selection;
    disp([num2str(length(cellInd_ofSubset)) ' cells selected.']);
end

if ischar(gene) % If a string, return all genes containing that string
    geneInd_ofSubset = find(contains(geneNames, gene));
    disp([num2str(length(geneInd_ofSubset)) ' genes containing ' gene ', including:']);
    disp([geneNames(geneInd_ofSubset)]);
elseif isempty(gene) % If a vector, return the vector
    geneInd_ofSubset = (1:length(geneNames))';
else 
    geneInd_ofSubset = gene;
end

D_ofSubset = D(geneInd_ofSubset,cellInd_ofSubset);

if makeGraph == 1;
    figure;
    
    %%% Is the data already log transformed?
    %imagesc(log(D_ofSubset));
    imagesc(D_ofSubset);

    %Axis Setup
    ax=gca;
    set(ax, 'TickDir','out',...
        'yTickLabel',geneNames(geneInd_ofSubset),...
        'ytick',(1:size(D_ofSubset,1)),...
        'xTickLabel',(cellTypes(cellInd_ofSubset)),...
        'xtick',[1:length(cellInd_ofSubset)],...
        'xTickLabelRotation',45);
else
end

end