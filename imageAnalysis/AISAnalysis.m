function [axonDist, dist_binned, AIS_binned, AIS_err, NaV_binned, NaV_err] = AISAnalysis(f_name_swc, f_name_AIS, f_name_NaV)

% %Read masked AIS
info = imfinfo(f_name_AIS);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
AISImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name_AIS, i);
    AISImageMat(:,:,i) = curImage;
end

%Read NaV image file
info = imfinfo(f_name_NaV);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
NaVImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name_NaV, i);
    NaVImageMat(:,:,i) = curImage;
end

%Read SWC file
M = dlmread(f_name_swc, ' ', 6, 0); %6 rows for header
axon_coord = M(:,3:5);

% go through for each pixel to build the 3D plot of the image
Ncoords = size(axon_coord,1);
axonDist = zeros(1,Ncoords);

startPt = axon_coord(1, :);
for i=1:Ncoords
    axonDist(i) = pdist([axon_coord(i,:); startPt]);
end

AISfluor = zeros(1,Ncoords);
NaVfluor = zeros(1,Ncoords);

% parameters for 100x image
micronsPerPixel_XY = 0.0947379;
micronsPerPixel_Z = 0.125;
% larger cube size means more samples
cubeSize_microns = 8; % mutable
cubeSize_pix_XY = ceil(cubeSize_microns / micronsPerPixel_XY);
cubeSize_pix_Z = ceil(cubeSize_microns / micronsPerPixel_Z);

% this takes a cube for a given point in swc and finds the avg intensity
for i=1:Ncoords
    curCoord_pix = round(axon_coord(i,:) ./ [micronsPerPixel_XY, micronsPerPixel_XY, micronsPerPixel_Z]);
    
    tempX = round([curCoord_pix(1)-cubeSize_pix_XY/2:curCoord_pix(1)+cubeSize_pix_XY/2]);
    tempY = round([curCoord_pix(2)-cubeSize_pix_XY/2:curCoord_pix(2)+cubeSize_pix_XY/2]);
    tempZ = round([curCoord_pix(3)-cubeSize_pix_Z/2:curCoord_pix(3)+cubeSize_pix_Z/2]);
    tempX = tempX(tempX > 0 & tempX <= w);
    tempY = tempY(tempY > 0 & tempY <= h);
    tempZ = tempZ(tempZ > 0 & tempZ <= Nframes);
    
    selectedPortion_ind{1} = tempX;
    selectedPortion_ind{2} = tempY;
    selectedPortion_ind{3} = tempZ;
    
    AISPortion = AISImageMat(selectedPortion_ind{2},selectedPortion_ind{1},selectedPortion_ind{3}); %X,Y vs row,col
    NaVPortion = NaVImageMat(selectedPortion_ind{2},selectedPortion_ind{1},selectedPortion_ind{3});
    
    AISfluor(i) = mean(AISPortion(AISPortion>0));
    NaVfluor(i) = mean(NaVPortion(NaVPortion>0));
end

binSize = 4; % mutable
nBins = ceil(max(axonDist)/binSize);

dist_binned = zeros(1,nBins);
AIS_binned = zeros(1,nBins);
AIS_err = zeros(1,nBins);
NaV_binned = zeros(1,nBins);
NaV_err = zeros(1,nBins);

for i=1:nBins
    dist_binned(i) = binSize*i - binSize/2;
    AIS_vals = AISfluor(axonDist > (i-1)*binSize & axonDist <= i*binSize);
    AIS_binned(i) = mean(AIS_vals);
    AIS_err(i) = std(AIS_vals)./sqrt(length(AIS_vals));
    NaV_vals = NaVfluor(axonDist > (i-1)*binSize & axonDist <= i*binSize);
    NaV_binned(i) = mean(NaV_vals);
    NaV_err(i) = std(NaV_vals)./sqrt(length(NaV_vals));
end

