function mappedMaxPositions = alignMappedSurfaces(VZminmesh,VZmaxmesh,mappedMinPositions,mappedMaxPositions,validXborders,validYborders,conformalJump,patchSize)
if nargin < 8
  patchSize = 21;
  if nargin < 7
    conformalJump = 1;
  end
end
patchSize = ceil(patchSize/conformalJump);
% pad the surfaces by one pixel so that the size remains the same after the difference operation
VZminmesh = [[VZminmesh 10*max(VZminmesh(:))*ones(size(VZminmesh,1),1)]; 10*max(VZminmesh(:))*ones(1,size(VZminmesh,2)+1)];
VZmaxmesh = [[VZmaxmesh 10*max(VZmaxmesh(:))*ones(size(VZmaxmesh,1),1)]; 10*max(VZmaxmesh(:))*ones(1,size(VZmaxmesh,2)+1)];
% calculate the absolute differences in xy between neighboring pixels
tmp1 = diff(VZminmesh,1,1); tmp1 = tmp1(:,1:end-1); tmp2 = diff(VZminmesh,1,2); tmp2 = tmp2(1:end-1,:); dMinSurface = abs(tmp1+i*tmp2);
tmp1 = diff(VZmaxmesh,1,1); tmp1 = tmp1(:,1:end-1); tmp2 = diff(VZmaxmesh,1,2); tmp2 = tmp2(1:end-1,:); dMaxSurface = abs(tmp1+i*tmp2);
% retain the region of interest, with a resolution specified by conformalJump
dMinSurface = dMinSurface(validXborders(1):conformalJump:validXborders(2), validYborders(1):conformalJump:validYborders(2));
dMaxSurface = dMaxSurface(validXborders(1):conformalJump:validXborders(2), validYborders(1):conformalJump:validYborders(2));
% calculate the cost as the sum of absolute slopes on both surfaces
patchCosts = conv2(dMinSurface+dMaxSurface, ones(patchSize),'valid');
% find the minimum cost
[row,col] = find(patchCosts == min(min(patchCosts)),1);
row = round(row+(patchSize-1)/2); col = round(col+(patchSize-1)/2);
% calculate and apply the corresponding shift
linearInd = sub2ind(size(dMinSurface),row,col);
shift1 = mappedMaxPositions(linearInd,1)-mappedMinPositions(linearInd,1);
mappedMaxPositions(:,1) = mappedMaxPositions(:,1) - shift1;
shift2 = mappedMaxPositions(linearInd,2)-mappedMinPositions(linearInd,2);
mappedMaxPositions(:,2) = mappedMaxPositions(:,2) - shift2;