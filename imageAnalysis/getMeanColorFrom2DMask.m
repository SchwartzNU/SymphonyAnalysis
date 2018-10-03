function C = getMeanColorFrom2DMask(H, bgName)
[r, c, f, n] = size(H); %rows, cols, frames, colors

mask = imread(bgName);
mask = mask > 0;
Hbg = H;
for i=1:n
    for j=1:f
        Hbg(:,:,j,i) = H(:,:,j,i) .* mask;
    end    
    C(i) = mean(mean(mean(H(:,:,:,i))));
end