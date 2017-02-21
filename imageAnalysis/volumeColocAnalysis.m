function [pixelAvg, pixelAvg90, pixelAvg180, pixelAvg270, withinVals, vals90, vals180, vals270] = volumeColocAnalysis(image_fname)
Nchannels = 3;
cellChannel = 1;
quantChannel = 2;
searchArea = 20; %pixels

imageData = bfopen(image_fname);
rawImageSequence = imageData{1,1};
cellImageSeq = rawImageSequence(cellChannel:Nchannels:end, 1);
quantImageSeq = rawImageSequence(quantChannel:Nchannels:end, 1);

Nframes = length(cellImageSeq);
[pixX, pixY] = size(cellImageSeq{1});
cellImageMat = zeros(pixX, pixY, Nframes);
cellImageMask = zeros(pixX, pixY, Nframes);
quantImageMat = zeros(pixX, pixY, Nframes);
quantImageMat180 = zeros(pixX, pixY, Nframes);

if pixX == pixY
    quantImageMat90 = zeros(pixY, pixX, Nframes);
    quantImageMat270 = zeros(pixY, pixX, Nframes);
end
thresLevel = zeros(1, Nframes);

for i=1:Nframes
    cellImageMat(:,:,i) = cellImageSeq{i};
    quantImageMat(:,:,i) = quantImageSeq{i};
    quantImageMat180(:,:,i) = imrotate(quantImageSeq{i}, 180);
    
    if pixX == pixY
        quantImageMat90(:,:,i) = imrotate(quantImageSeq{i}, 90);
        quantImageMat270(:,:,i) = imrotate(quantImageSeq{i}, 270);
    end
    
    thresLevel(i) = graythresh(squeeze(cellImageMat(:,:,i)));
    %thresLevel(i) = 1;
    cellImageMask(:,:,i) = im2bw(cellImageMat(:,:,i), thresLevel(i));
    %cellImageMask(:,:,i) = cellImageMat(:,:,i) > 1500;
end
temp =  quantImageMat .* cellImageMask;
withinVals = temp(:);
withinValMean = mean(temp(:));


temp =  quantImageMat180 .* cellImageMask;
vals180 = temp(:);
withinVal180Mean = mean(temp(:));


if pixX == pixY
    temp =  quantImageMat90 .* cellImageMask;
    vals90 = temp(:);
    withinVal90Mean = mean(temp(:));
    
    temp =  quantImageMat270 .* cellImageMask;
    vals270 = temp(:);
    withinVal270Mean = mean(temp(:));
end

if pixX == pixY
    valsControl = [vals90; vals180; vals270];
else
    valsControl = vals180;
end

%pixelTriggeredAverage part
withinInd = find(cellImageMask==1);

L = length(withinInd);
pixelAvg = zeros(searchArea+1, searchArea+1);
pixelAvg180 = zeros(searchArea+1, searchArea+1);

if pixX == pixY
    pixelAvg90 = zeros(searchArea+1, searchArea+1);
    pixelAvg270 = zeros(searchArea+1, searchArea+1);
end


z = 0;
%L
%pause;
for i=1:L
   % i
    [x, y, f] = ind2sub([pixX, pixY, Nframes], withinInd(i));
    if x > round(searchArea/2) && x < pixX - round(searchArea/2) && y > round(searchArea/2) && y < pixY - round(searchArea/2);
        pixelAvg = pixelAvg + quantImageMat(x-round(searchArea/2):x+round(searchArea/2), y-round(searchArea/2):y+round(searchArea/2), f);
        pixelAvg180 = pixelAvg180 + quantImageMat180(x-round(searchArea/2):x+round(searchArea/2), y-round(searchArea/2):y+round(searchArea/2), f);
        
        if pixX == pixY
            pixelAvg90 = pixelAvg90 + quantImageMat90(x-round(searchArea/2):x+round(searchArea/2), y-round(searchArea/2):y+round(searchArea/2), f);
            pixelAvg270 = pixelAvg270 + quantImageMat270(x-round(searchArea/2):x+round(searchArea/2), y-round(searchArea/2):y+round(searchArea/2), f);
        end
        
        z=z+1;
    end
end
pixelAvg = pixelAvg./z;
pixelAvg180 = pixelAvg180./z;

if pixX == pixY
    pixelAvg90 = pixelAvg90./z;
    pixelAvg270 = pixelAvg270./z;  
else
   pixelAvg90 = [];
   pixelAvg270 = [];
   vals90 = [];
   vals270 = [];
end


