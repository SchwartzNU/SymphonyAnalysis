%function [] = fullSelectiveExpressionMatrix_pairs_par(allPairs, D_folder, cellTypes, geneNames, method)
%path
addpath('code/transcriptomeAnalysis/');
addpath('code/');

%load data
load('data/transcriptomicsData_01_2018.mat');
load('data/allPairs', 'allPairs');
%loads allPairs, D, geneNames, cellTypes

D_folder = 'genePairDataGMean';
out_folder = 'selectedGenePairs_logRatio';
method = 'logRatio';

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

selectedPairs = cell(1,Ntypes);
selectedPairScores = cell(1,Ntypes);

parpool('local', 20);

%parameters
%falseNeg_scaling = .65;
%interestThreshold = 0.8*falseNeg_scaling;
interestThreshold = 2; %log units

parfor c=1:N_chunks
    tic;
    disp(['loading: ' D_folder filesep 'genePairs_' num2str(c)]);
    temp = load([D_folder filesep 'genePairs_' num2str(c)], 'D_pairs');
    D_pairs = temp.D_pairs;
    [chunkSize, Ncells] = size(D_pairs);
    
    if ~strcmp(method, 'fractionPresent')
        D_pairs=D_pairs*1000; %make the minimum about 14
        D_pairs(D_pairs<2) = 1;
        logD = log10(D_pairs);
    end
     
    selectedPairs = [];
    selectedPairScores = [];
    
    %D_pairs = D_pairs(:, ind); %now sorted by cell types
    for t=1:Ntypes
        
        indexVals = zeros(chunkSize, 1);
        if NofEach_sorted(t) > 2
            curType = uniqueTypes_sorted{t};
            targetInd = targetInd_all{t};
            disp(['Type: ' curType  ', N = ' num2str(length(targetInd))]);            
            othersInd = setdiff(1:Ncells, targetInd);
                        
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
                elseif strcmp(method, 'p-value')
                    targetVals = logD(i,targetInd);
                    otherVals = logD(i,othersInd);
                    [~, indexVals(i)] = ttest2(targetVals, otherVals, 'tail', 'right');
                    %[indexVals_sorted, ind] = sort(indexVals, 'ascend');                    
                elseif strcmp(method, 'medVmax')
                     targetVals = logD(i,targetInd);
                     otherVals = logD(i,othersInd);
                     indexVals(i) = median(targetVals) - max(otherVals);
%                      if max(targetVals) > 0
%                          keyboard;
%                      end
                elseif strcmp(method, 'logRatio')
                    targetVals = logD(i,targetInd);
                    otherVals = logD(i,othersInd);
                    indexVals(i) = median(targetVals) - mean(otherVals);
                else
                    %%%TBD
                end
            end
        end
        selectedPairs{t} = (c-1)*chunkSize+find(indexVals > interestThreshold);
        selectedPairScores{t} = indexVals(indexVals > interestThreshold);
        %selectedPairs = (c-1)*chunkSize+find(indexVals < interestThreshold);
        %selectedPairScores = indexVals(indexVals < interestThreshold);
        toc;
        
        %display stuff
        disp(['Max indexVal = ' num2str(max(indexVals))]);
        if ~isempty(selectedPairs)
            disp(['Chunk ' num2str(c) ' type '  uniqueTypes_sorted{t} ': ' num2str(length(selectedPairs)) ' pairs found.']); 
        end
        saveDataFiles([out_folder filesep 'selectedPairs_' num2str(c)], ...
            selectedPairs, 'selectedPairs', selectedPairScores, 'selectedPairScores');

    end
end    
