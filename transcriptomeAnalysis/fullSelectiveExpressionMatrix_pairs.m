function [] = fullSelectiveExpressionMatrix_pairs(allPairs, D_folder, cellTypes, geneNames, method)

uniqueTypes = unique(cellTypes);

Ntypes = length(uniqueTypes);
NofEach = zeros(1,Ntypes);

Npairs = size(allPairs, 1);

%sort by most prevalent
for i=1:Ntypes
    NofEach(i) = length(find(strcmp(uniqueTypes{i}, cellTypes)));
end
[NofEach_sorted, ind] = sort(NofEach, 'descend');
uniqueTypes_sorted = uniqueTypes(ind);

Ntestable = length(find(NofEach>2));

%sort by type
ind = [];
for i=1:Ntypes
    curInd = find(strcmp(uniqueTypes_sorted{i}, cellTypes));
    targetInd_all{i} = curInd;
    ind = [ind, curInd];
end
%ind
%D_sorted = D(:,ind); use ind to order columns of each D part

cellTypes = cellTypes(ind);
%make full matrix
%D_topGenes = zeros(Ngenes*Ntestable,length(cellTypes));
allGeneNames = [];

d = dir(D_folder);
d_ind = strmatch('genePairs', strvcat(d.name));
N_chunks = length(d_ind);

z=0;
selectedPairs = cell(1,Ntypes);
selectedPairScores = cell(1,Ntypes);

for c=1:N_chunks
    tic;
    disp(['loading: ' D_folder filesep 'genePairs_' num2str(c)]);
    load([D_folder filesep 'genePairs_' num2str(c)], 'D_pairs');
    [chunkSize, Ncells] = size(D_pairs);
    %D_pairs = D_pairs(:, ind); %now sorted by cell types
    for t=1:Ntypes
        
        indexVals = zeros(chunkSize, 1);
        
        if NofEach_sorted(t) > 2
            curType = uniqueTypes_sorted{t};
            targetInd = targetInd_all{t};
            disp(['Type: ' curType  ', N = ' num2str(length(targetInd))]);            
            othersInd = setdiff(1:Ncells, targetInd);
            
            %parameters
            falseNeg_scaling = .65;
            interestThreshold = 0.8*falseNeg_scaling;
            
            for i=1:chunkSize
                if strcmp(method, 'fractionPresent')
                    Nmatch = sum(D_pairs(i,targetInd));
                    if Nmatch < 3 %horrible hack
                        targetFrac = 0;
                    else
                        targetFrac = sum(D_pairs(i,targetInd))./length(targetInd);
                    end
                    otherFrac = sum(D_pairs(i,othersInd))./length(othersInd);
                    indexVals(i) = falseNeg_scaling*targetFrac - (1-falseNeg_scaling)*otherFrac;                    
                else
                    %%%TBD
                end
            end
        end
        selectedTemp = z+find(indexVals > interestThreshold);
        selectedScoresTemp = indexVals(indexVals > interestThreshold);
        toc;
        disp(['Max indexVal = ' num2str(max(indexVals))]);
        if ~isempty(selectedTemp)
            disp(['Chunk ' num2str(c) ' type '  uniqueTypes_sorted{t} ': ' num2str(length(selectedTemp)) ' pairs found.']); 
        end
        selectedPairs{t} = [selectedPairs{t}; selectedTemp];
        selectedPairScores{t} = [selectedPairScores{t}; selectedScoresTemp];
    end
    z=z+chunkSize;
end

save('selectiveGenePairs', 'selectedPairs'); 
keyboard;


% [indexVals_sorted, ind] = sort(indexVals, 'descend');        
