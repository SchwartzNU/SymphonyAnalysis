function R = getSpectralSignatureFromMask(H, maskName, bgColor)
%H is 4D image matrix, [r, c, frame, color]
%colorOrder is a string of letters for the colors ,e.g. 'BRCY'

[r, c, f, n] = size(H); %rows, cols, frames, colors
if ~isempty(bgColor)
    useBg = 1;
else
    useBg = 0;
end
info = imfinfo(maskName);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
mask = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(maskName, i);
    mask(:,:,i) = curImage;
    %control: transpose mask;
    %mask(:,:,i) = curImage';
end

mask = mask > 0; %make binary

mask_full = zeros(size(H));
for i=1:n
    mask_full(:,:,:,i) = mask;
end

if useBg
    for i=1:n
        H(:,:,:,i) = H(:,:,:,i) ./ bgColor(i);
    end
else
    %median normalize each color channel
    for i=1:n
        m = median(reshape(H(:,:,:,i), [r*c*f, 1]));
        H(:,:,:,i) = H(:,:,:,i)./m;
    end
end
% ratio_ind = nchoosek(1:n, 2); 
% nR = size(ratio_ind, 1);

% npix = sum(mask(:));
% R = zeros(npix,nR); %all ratios, each pixel
npix = sum(mask(:));
R = zeros(npix,n); %colors, each pixel


for i=1:n
    curImage = mask_full .* H;
    curImage = curImage(:,:,:,i);
    curImage = curImage(mask>0);
%     r1 = ratio_ind(i,1);
%     r2 = ratio_ind(i,2);    
%     curRatioImage = (curImage(:,:,:,r1) - curImage(:,:,:,r2)) ...
%         ./ (curImage(:,:,:,r1) + curImage(:,:,:,r2));
%     %curRatioImage = (curImage(:,:,:,r1) ./ curImage(:,:,:,r2));
%     curRatioImage = curRatioImage(mask>0);
    R(:,i) = reshape(curImage, [npix, 1]);
end



