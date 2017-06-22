function [activationMatrix, A, angles, RF] = radonModel(x, y, RFsize, Nangles, Nbars, barWidth, barSpacing)
%x and y are RF positions with center being 0,0
%RF size is 1 sigma s.d. 


%create receptive field
S = 1000; %total size of screen = 1000 x 1000 pixels
RF = fspecial('gaussian', S, RFsize);
RF = circshift(RF, [y, x]); %this is correct, circshift shifts columns then rows

%set bar locations once (to be rotated for each angle)
barLocations = round(linspace(-barSpacing*ceil(Nbars/2),barSpacing*ceil(Nbars/2),Nbars));    

%make bar images 
middleX = round(S/2);
for i=1:Nbars
   barImages{i} = zeros(S,S);
   barImages{i}(middleX + barLocations(i) - floor(barWidth/2):middleX + barLocations(i) - floor(barWidth/2) + barWidth -1, :) = 1;
   %barImages{i}(middleX + barLocations(i):middleX + barLocations(i) + barWidth -1, :) = 1;
end

%set angles (degrees)
angles = round(0:360/Nangles:359);

A = zeros(Nangles, Nbars*barSpacing);
%for each image and angle, calculate the overlap with the RF
activationMatrix = zeros(Nangles, Nbars);
for i=1:Nangles
    for j=1:Nbars
        %barImage = imrotate(barImages{j}, angles(i)-90, 'bilinear');
        barImage = imrotate(barImages{j}, angles(i)-90, 'bilinear', 'crop');
%         [sizeDiffX, sizeDiffY] = size(barImage);
%         sizeDiffX = sizeDiffX - S;
%         sizeDiffY = sizeDiffY - S;
%         RF_padded = padarray(RF, [ceil(sizeDiffX/2), ceil(sizeDiffY/2)], 'replicate');
%         if size(RF_padded, 1) > size(barImage, 1)
%             RF_padded = RF_padded(2:end,:);
%         end
%         if size(RF_padded, 2) > size(barImage, 2)
%             RF_padded = RF_padded(:,2:end);
%         end
        activationMatrix(i,j) = sum(sum(barImage.*RF));        
    end    
end

A = flipud(activationMatrix');

radonSize = 2*ceil(norm(size(RF)-floor((size(RF)-1)/2)-1))+3; %from radon.m documentation
Anew = zeros(radonSize, Nangles);

scaleFactor = radonSize/size(RF,1);

for i=1:Nangles
    Anew(:,i) = interp1(barLocations * scaleFactor + floor(radonSize/2),  A(:,i), 1:radonSize, ...
        'linear', 0); 
end

A = Anew;
% 
% %A = resample(A,barSpacing,1,barSpacing/2);
% %A = A(1:end-barSpacing*1,:);
% Alen = size(A, 1);
% A(A<0.1) = 0;
% 
% Rsize = round(S*sqrt(2)) + 5; %why!!!
% sizeDiff = Rsize - Alen;
% A = padarray(A, [floor(sizeDiff/2)]);
% A = circshift(A,barSpacing-5);


