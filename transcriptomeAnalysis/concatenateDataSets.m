function [cellIDs_all, cellType_all, D_all, eyeVec_all, geneCounts_all, xPos_all, yPos_all, geneNames] = concatenateDataSets(varargin)
cellIDs_all = [];
cellType_all = [];
D_all = [];
eyeVec_all = [];
geneCounts_all = [];
xPos_all = [];
yPos_all = [];
for i=1:nargin
    setName = varargin{i};
    load(setName);    
    cellIDs_all = [cellIDs_all, cellIDs];
    cellType_all = [cellType_all, cellType];
    eyeVec_all = [eyeVec_all, eyeVec];
    xPos_all = [xPos_all, xPos];
    yPos_all = [yPos_all, yPos];
    geneCounts_all = [geneCounts_all, geneCounts];
    D_all = [D_all, D];
end