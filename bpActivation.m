function bpContrasts = bpActivation(fname, RFsize, bpX, bpY)
micronsPerPixel = 1.38; %rigA
M = imread(['StimulusImages/' fname '.png']);
M = (double(M)-127)/127; %now in units of contrast

RFsize_pix = round(RFsize/micronsPerPixel);
winSize = 4*RFsize_pix;
gaussWin = fspecial('gaussian', winSize, RFsize_pix);

bpRFsize_pix = round(22/micronsPerPixel);
bpwinSize = 4*bpRFsize_pix;
bpgaussWin = fspecial('gaussian', bpwinSize, bpRFsize_pix);

L = length(bpX);
bpContrasts = zeros(1, L);

[r,c] = size(M);
initX = round(r/2);
initY = round(c/2);

for i=1:L
    startX =  initX + bpX(i) - round(bpwinSize/2);
    startY =  initY + bpY(i) - round(bpwinSize/2);
    if startX>0 && startY>0
        bpContrasts(i) = sum(sum(bpgaussWin.*M(startX:startX+bpwinSize-1, startY:startY+bpwinSize-1)));
    end
end