function [DAFfluor, bg_fluor, dendDist, dist_binned, f_binned, f_err] = DAFImagingAnalysis(f_name_traced, f_name_DAF, f_name_swc)

%Read SWC file
M = dlmread(f_name_swc, ' ', 6, 0); %6 rows for header
dend_coord = M(:,3:5);

% %Read masked dendrites file
info = imfinfo(f_name_traced);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
cellImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name_traced, i);
    cellImageMat(:,:,i) = curImage;
end

%Read DAF image file
info = imfinfo(f_name_DAF);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
DAFImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name_DAF, i);
    DAFImageMat(:,:,i) = curImage;
end

Ncoords = size(dend_coord,1);
dist_start = zeros(Ncoords,1);
dist_end = zeros(Ncoords,1);

%startPt = input('Enter dendrite start point [x, y, z]: ');
startPt = [578 539 14]; %microns

dendDist = zeros(1,Ncoords);

for i=1:Ncoords
    dendDist(i) = pdist([dend_coord(i,:); startPt]);
end

DAFfluor = zeros(1,Ncoords);
bg_fluor = zeros(1,Ncoords);
%parameters
micronsPerPixel_XY = 1.243;
micronsPerPixel_Z = 1;
cubeSize_microns = 4;
cubeSize_pix_XY = ceil(cubeSize_microns / micronsPerPixel_XY);
cubeSize_pix_Z = ceil(cubeSize_microns / micronsPerPixel_Z);

for i=1:Ncoords
    curCoord_pix = round(dend_coord(i,:) ./ [micronsPerPixel_XY, micronsPerPixel_XY, micronsPerPixel_Z]);
    
    tempX = round([curCoord_pix(1)-cubeSize_pix_XY/2:curCoord_pix(1)+cubeSize_pix_XY/2]);
    tempY = round([curCoord_pix(2)-cubeSize_pix_XY/2:curCoord_pix(2)+cubeSize_pix_XY/2]);
    tempZ = round([curCoord_pix(3)-cubeSize_pix_Z/2:curCoord_pix(3)+cubeSize_pix_Z/2]);
    tempX = tempX(tempX > 0 & tempX <= w);
    tempY = tempY(tempY > 0 & tempY <= h);
    tempZ = tempZ(tempZ > 0 & tempZ <= Nframes);
    
    selectedPortion_ind{1} = tempX;
    selectedPortion_ind{2} = tempY;
    selectedPortion_ind{3} = tempZ;
    
    cellPortion = cellImageMat(selectedPortion_ind{2},selectedPortion_ind{1},selectedPortion_ind{3}); %X,Y vs row,col
    DAFPortion = DAFImageMat(selectedPortion_ind{2},selectedPortion_ind{1},selectedPortion_ind{3});
    
    %    figure(1);
    %    subplot(2,1,1);
    %    imagesc(squeeze(max(cellPortion,[],3)));
    %    subplot(2,1,2);
    %    imagesc(squeeze(max(DAFPortion,[],3)));
    DAFfluor(i) = mean(DAFPortion(cellPortion>0));
    bg_ind = cellPortion==0;    
    %sum(bg_ind(:))
    if sum(bg_ind(:)) < .7*numel(DAFPortion)
        bg_fluor(i) = mean(DAFPortion(:));
%         i
%         DAFfluor(i)
%         bg_fluor(i)
%         pause;
    else
        bg_fluor(i) = mean(DAFPortion(bg_ind));
    end
end

binSize = 5;
nBins = ceil(max(dendDist)/binSize);

dist_binned = zeros(1,nBins);
f_binned = zeros(1,nBins);
f_err = zeros(1,nBins);

f_all = (DAFfluor - bg_fluor) ./ bg_fluor;

for i=1:nBins
    dist_binned(i) = binSize*i - binSize/2;
    f_vals = f_all(dendDist > (i-1)*binSize & dendDist <= i*binSize);
    f_binned(i) = mean(f_vals);
    f_err(i) = std(f_vals)./sqrt(length(f_vals));
end



%calculate minimum distance
%dist_start = euclideandist(dend_coor,startpt);
%dist_end = euclideandist(dend_coor,endpt);
=======
function [DAFfluor, bg_fluor, dendDist, dist_binned, f_binned, f_err] = DAFImagingAnalysis(f_name_traced, f_name_DAF, f_name_swc)

%Read SWC file
M = dlmread(f_name_swc, ' ', 6, 0); %6 rows for header
dend_coord = M(:,3:5);

% %Read masked dendrites file
info = imfinfo(f_name_traced);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
cellImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name_traced, i);
    cellImageMat(:,:,i) = curImage;
end

%Read DAF image file
info = imfinfo(f_name_DAF);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
DAFImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name_DAF, i);
    DAFImageMat(:,:,i) = curImage;
end

Ncoords = size(dend_coord,1);
dist_start = zeros(Ncoords,1);
dist_end = zeros(Ncoords,1);

%startPt = input('Enter dendrite start point [x, y, z]: ');
startPt = [578 539 14]; %microns

dendDist = zeros(1,Ncoords);

for i=1:Ncoords
    dendDist(i) = pdist([dend_coord(i,:); startPt]);
end

DAFfluor = zeros(1,Ncoords);
bg_fluor = zeros(1,Ncoords);
%parameters
micronsPerPixel_XY = 1.243;
micronsPerPixel_Z = 1;
cubeSize_microns = 4;
cubeSize_pix_XY = ceil(cubeSize_microns / micronsPerPixel_XY);
cubeSize_pix_Z = ceil(cubeSize_microns / micronsPerPixel_Z);

for i=1:Ncoords
    curCoord_pix = round(dend_coord(i,:) ./ [micronsPerPixel_XY, micronsPerPixel_XY, micronsPerPixel_Z]);
    
    tempX = round([curCoord_pix(1)-cubeSize_pix_XY/2:curCoord_pix(1)+cubeSize_pix_XY/2]);
    tempY = round([curCoord_pix(2)-cubeSize_pix_XY/2:curCoord_pix(2)+cubeSize_pix_XY/2]);
    tempZ = round([curCoord_pix(3)-cubeSize_pix_Z/2:curCoord_pix(3)+cubeSize_pix_Z/2]);
    tempX = tempX(tempX > 0 & tempX <= w);
    tempY = tempY(tempY > 0 & tempY <= h);
    tempZ = tempZ(tempZ > 0 & tempZ <= Nframes);
    
    selectedPortion_ind{1} = tempX;
    selectedPortion_ind{2} = tempY;
    selectedPortion_ind{3} = tempZ;
    
    cellPortion = cellImageMat(selectedPortion_ind{2},selectedPortion_ind{1},selectedPortion_ind{3}); %X,Y vs row,col
    DAFPortion = DAFImageMat(selectedPortion_ind{2},selectedPortion_ind{1},selectedPortion_ind{3});
    
    %    figure(1);
    %    subplot(2,1,1);
    %    imagesc(squeeze(max(cellPortion,[],3)));
    %    subplot(2,1,2);
    %    imagesc(squeeze(max(DAFPortion,[],3)));
    DAFfluor(i) = mean(DAFPortion(cellPortion>0));
    bg_ind = cellPortion==0;    
    %sum(bg_ind(:))
    if sum(bg_ind(:)) < .7*numel(DAFPortion)
        bg_fluor(i) = mean(DAFPortion(:));
%         i
%         DAFfluor(i)
%         bg_fluor(i)
%         pause;
    else
        bg_fluor(i) = mean(DAFPortion(bg_ind));
    end
    %
end

binSize = 5;
nBins = ceil(max(dendDist)/binSize);

dist_binned = zeros(1,nBins);
f_binned = zeros(1,nBins);
f_err = zeros(1,nBins);

f_all = (DAFfluor - bg_fluor) ./ bg_fluor;

for i=1:nBins
    dist_binned(i) = binSize*i - binSize/2;
    f_vals = f_all(dendDist > (i-1)*binSize & dendDist <= i*binSize);
    f_binned(i) = mean(f_vals);
    f_err(i) = std(f_vals)./sqrt(length(f_vals));
end



%calculate minimum distance
%dist_start = euclideandist(dend_coor,startpt);
%dist_end = euclideandist(dend_coor,endpt);
