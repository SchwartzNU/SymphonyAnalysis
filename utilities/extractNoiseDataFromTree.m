function [allMeans, allSDs] = extractNoiseDataFromTree(T, Ncond)
%T is analysis tree
cellTypeNode = T.getchildren(1);
cellNodes = T.getchildren(cellTypeNode);

L = length(cellNodes);
allMeans = ones(L*Ncond,1)*nan;
allSDs = ones(L*Ncond,1)*nan;

z=1;
for i=1:L
    sT = T.subtree(cellNodes(i));
    leafNodes = sT.findleaves;
    nLeaves = length(leafNodes);
    
    for j=1:nLeaves
        curNode = sT.get(leafNodes(j));
        %allMeans(z) = curNode.spikeCount_100ms_around_PSTH_peak.mean;
        allMeans(z) = curNode.ONSET_FRmax.value
        allSDs(z) = curNode.spikeCount_100ms_around_PSTH_peak.SD;
        z=z+1;
    end
end