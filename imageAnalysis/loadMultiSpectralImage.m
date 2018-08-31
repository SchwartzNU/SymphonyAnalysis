function H = loadMultiSpectralImage(image_fname, Ncolors)

imageData = bfopen(image_fname);
%keyboard;
rawImageSequence = imageData{1,1};
for c=1:Ncolors
    H_cell{c} = rawImageSequence(c:Ncolors:end,1);
end

Nframes = length(H_cell{1});
[nR, nC] =  size(H_cell{1}{1});
H = zeros(nR, nC, Nframes, Ncolors);
for c=1:Ncolors
    for f=1:Nframes
       H(:,:,f,c) = H_cell{c}{f}; 
    end
end

