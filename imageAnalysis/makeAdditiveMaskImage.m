function [I, Iproj] = makeAdditiveMaskImage(H, N)

[r, c, f, n] = size(H); %rows, cols, frames, colors
I = zeros(size(H));



for i=0:N
    if exist(['p' num2str(i) '.tif'])
        disp(['Processing mask ' num2str(i) ' of ' num2str(N)]);
        for frameInd=1:f
            curImage = imread(['p' num2str(i) '.tif'], frameInd);
            mask(:,:,frameInd) = curImage;
        end
        mask = mask > 0; %make binary
      
        for j=1:n
            maskedImage = mask .* H(:,:,:,j);
            temp = maskedImage>0;
            meanColor = mean(mean(mean(maskedImage(temp))));
            maskedImage(temp) = meanColor;
            %I(:,:,:,j) = I(:,:,:,j) + mask .* H(:,:,:,j);
            I(:,:,:,j) = I(:,:,:,j) + maskedImage;
        end
    end
end

Iproj = squeeze(max(I, [], 3));

%normalize
for i=1:n
    Iproj(:,:,i) = Iproj(:,:,i) ./ max(max(Iproj(:,:,i)));
end

