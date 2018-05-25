image_fname = 'Cell2_NB_Mask.tif';
punctaPoints_fname = 'punctaPoints.mat';
micronsPerPixelXY = 0.2497912;
micronsPerPixelZ = 0.25;

info = imfinfo(image_fname);
for i=1:numel(info)
    cellMask_full(:,:,i) = imresize(imread(image_fname, i), micronsPerPixelXY);
end
[maskPointsX, maskPointsY, maskPointsZ] = ind2sub(size(cellMask_full), find(cellMask_full>0));
maskPointsZ = maskPointsZ * micronsPerPixelZ;

cellMask = squeeze(max(cellMask_full, [], 3) > 0);

% A = dlmread('010517Ac3_PSD_masked_puncta.xls', '\t', 1, 0);
% allX = A(:,12);
% allY = A(:,13);
% allZ = A(:,14);

load(punctaPoints_fname,'COM');
allX = COM(:,1);
allY = COM(:,2);
allZ = COM(:,3);

allX = allX * micronsPerPixelXY;
allY = allY * micronsPerPixelXY;
allZ = allZ * micronsPerPixelZ;

L = length(allX);
D = ones(L,L) * nan;

for i=1:L
    for j=i+1:L
        D(i,j) = sqrt((allX(j) - allX(i))^2 + (allY(j) - allY(i))^2 + (allZ(j) - allZ(i))^2);
    end
end

[minVal, minInd] = min(D);

distVals = zeros(L, 1);
centerPoints = zeros(L, 3);
for i=1:L
    if minVal(i) < 20
        distVals(i) = minVal(i);
        centerPoints(i, 1) = mean([allX(i), allX(minInd(i))]);
        centerPoints(i, 2) = mean([allY(i), allY(minInd(i))]);
        centerPoints(i, 3) = mean([allZ(i), allZ(minInd(i))]);
    else
        distVals(i) = nan;
        centerPoints(i, :) = [nan nan nan];
    end
end

ind = find(isnan(distVals));
distVals = distVals(setdiff(1:L, ind));
centerPoints = centerPoints(setdiff(1:L, ind), :);

% L = length(distVals);Vq = interp2(X,Y,V,Xq,Yq) r
% for i=1:L
%     
% end
% A
V = griddata(centerPoints(:,1),centerPoints(:,2),centerPoints(:,3),1./distVals,maskPointsY,maskPointsX,maskPointsZ);

densityMap = cellMask * nan;
for i=1:length(maskPointsX)
    if ~isnan(V(i))
        densityMap(maskPointsX(i),maskPointsY(i)) = V(i);
    else
        densityMap(maskPointsX(i),maskPointsY(i)) = 0;
        %nanmean(V);
    end
end

imageFilter=fspecial('gaussian',50,6);
densityMap_filtered = nanconv(densityMap,imageFilter,'nanout');
nanmean(densityMap(:))
