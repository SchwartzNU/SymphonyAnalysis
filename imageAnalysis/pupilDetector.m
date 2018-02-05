basename = 'Cropped_thresholded';
Nfiles = 2360;
%Nfiles = 100;

radii = zeros(1,Nfiles);
for i=1:Nfiles
    img = imread([basename, num2str(i-1,'%04d') '.tif']);
    if i==1
        [r, c] = size(img);
    end
    %invert
    img = img<255;
    img = imerode(img,strel('disk',1));
    stats = regionprops(img,'Area','EquivDiameter','ConvexArea','solidity','centroid');
    ind = bestCircle(stats, r, c, 20, .9);
    while(isempty(ind))
        img = imerode(img,strel('disk',1));
        stats = regionprops(img,'Area','EquivDiameter','ConvexArea','solidity','centroid');
        ind = bestCircle(stats, r, c, 20, .9);
    end
    
    radii(i) = stats(ind).EquivDiameter;
    
    
    %    figure(1);
    %    imshow(img);
    %    pause;
    
end



