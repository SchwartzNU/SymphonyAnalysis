%punctaMaskFinder(f_name, thres, pixels, baselineFrames)
f_name_puncta = 'Objects map of Result of All connected regions.tif';
f_name_NB = 'Cell2_NB_Mask.tif';
fname_stats = 'Statistics for Result of All connected regions.txt';
overlapThreshold = 0.5;

info = imfinfo(f_name_puncta);
Nframes = numel(info);
w = info(1).Width;
h = info(1).Height;
punctaImageMat = zeros(h,w,Nframes);
cellImageMat = zeros(h,w,Nframes);

%load images into matrix
for i=1:Nframes
    curImage = imread(f_name_puncta, i);
    punctaImageMat(:,:,i) = curImage;
    curImage = imread(f_name_NB, i);
    cellImageMat(:,:,i) = curImage;
end

punctaImageMat_binary = punctaImageMat > 0;

[labelVals, Nobj] = bwlabeln(punctaImageMat_binary);
Nobj
fractionOverlap = zeros(1, Nobj);
closestPunctaInd = zeros(1, Nobj);


%load punta COM locations
A = dlmread(fname_stats, ',', 1, 0);
allX = A(:,12);
allY = A(:,13);
allZ = A(:,14);

COM = zeros(Nobj, 3);
D = zeros(1,Nobj);
temp = regionprops(punctaImageMat_binary, 'Centroid');
for i=1:Nobj
    COM(i,:) = temp(i).Centroid;
    for j=1:Nobj
        D(j) = sqrt(sum(([allX(j), allY(j), allZ(j)] - COM(i,:)).^2));
    end
    [~, closestPunctaInd(i)] = min(D);
end

%D = [allX, allY, allZ] - COM;

%find fraction overlap
for i=1:Nobj
    i
    maskPixInd = find(labelVals == i);    
    maskPixels = length(maskPixInd);
    overlapPixels = length(find(labelVals == i & cellImageMat > 0));
    fractionOverlap(i) = overlapPixels ./ maskPixels;    
end
countedPunctaInd = fractionOverlap>overlapThreshold;
COM = COM(countedPunctaInd, :);

countedPuncta = closestPunctaInd(fractionOverlap>overlapThreshold);
Xpos = allX(countedPunctaInd);
Ypos = allY(countedPunctaInd);


save('punctaPoints.mat','-v7.3')

