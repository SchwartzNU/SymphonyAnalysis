function [xPoints, yPoints, signalMat, deltaFoverF, dendDist] = caImagingAnalysis(f_name, thres, pixels, baselineFrames)

info = imfinfo(f_name);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
cellImageMat = zeros(h,w,Nframes);

for i=1:Nframes
    curImage = imread(f_name, i);
    background = imopen(curImage,strel('disk',5));
    curImage = curImage - background;
    cellImageMat(:,:,i) = curImage;
    
end

meanImage = mean(cellImageMat, 3);
cellImageMask = meanImage > thres;
cellImageMask = bwareaopen(cellImageMask, 50);
figure;
imagesc(meanImage);
disp('Draw a line along the middle of the ROI. Double click to finish');
[xpts, ypts] = getline(gcf);
if xpts(1) < w/2
    allX = 1:w;
else
    allX = w:-1:1;
end
allY = interp1(xpts, ypts, allX);

[X,Y] = meshgrid(1:w,1:h);

%nearPoints = zeros(h,w,w);
z=1;
for i=1:w
    if ~isnan(allY(i))
        x = allX(i);
        y = allY(i);
        dist_2 = sum(bsxfun(@minus, [X(:), Y(:)], [x, y]) .^ 2, 2);
        dist_2(cellImageMask(sub2ind([h, w], Y(:), X(:))) == 0) = Inf;
        [~, ind] = sort(dist_2);
        selectedInd = ind(1:pixels);
        
        dist_2(selectedInd(pixels));
        if dist_2(selectedInd(pixels)) < Inf
            nearPoints = zeros(h,w);
            [xNear, yNear] = ind2sub([h, w], selectedInd);
            nearPoints(xNear, yNear) = 1;
%             imagesc(nearPoints);
%             pause;
            xPoints(z) = x;
            yPoints(z) = y; 
            signalMat(z,:) = squeeze(mean(mean(cellImageMat(xNear, yNear, :))));
            bg = mean(signalMat(z,1:baselineFrames));
            deltaFoverF(z) = (mean(signalMat(z,baselineFrames+1:end)) - bg) / bg;
            z=z+1;
        end
    end      
end

refPointX = xPoints(1);
refPointY = yPoints(1);

dendDist = sqrt((xPoints - refPointX).^2 + (yPoints - refPointY).^2);


