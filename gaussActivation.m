function [v, vRectOn, vRectOff, bpContrasts] = gaussActivation(fname, RFsize)
micronsPerPixel = 1.38; %rigA
M = imread(['StimulusImages/' fname '.png']);
M = (double(M)-127)/127; %now in units of contrast

RFsize_pix = round(RFsize/micronsPerPixel);
winSize = 4*RFsize_pix;
gaussWin = fspecial('gaussian', winSize, RFsize_pix);

bpRFsize_pix = round(22/micronsPerPixel);
bpwinSize = 4*bpRFsize_pix;
bpgaussWin = fspecial('gaussian', bpwinSize, bpRFsize_pix);

%crop image
borderSizeX = size(M,1) - winSize;
borderSizeY = size(M,2) - winSize;

X_start = round(borderSizeX/2);
Y_start = round(borderSizeY/2);
M_cropped = M(X_start:X_start+winSize-1, Y_start:Y_start+winSize-1);
M_posRect = M_cropped;
M_posRect(M_posRect<0) = 0;
M_negRect = M_cropped;
M_negRect(M_negRect>0) = 0;

v = sum(sum(M_cropped .* gaussWin));
vRectOn = sum(sum(M_posRect .* gaussWin));
vRectOff = sum(sum(M_negRect .* -gaussWin));

bpContrasts = zeros(1, winSize^2);
z=1;
for i=1:winSize
    for j=1:winSize
        startX = X_start + i - round(bpwinSize/2);
        startY = Y_start + j - round(bpwinSize/2);
        bpContrasts(z) = sum(sum(bpgaussWin.*M(startX:startX+bpwinSize-1, startY:startY+bpwinSize-1)));
        z=z+1;
    end
end