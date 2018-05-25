[r,c, L] = size(cellMask_full);
micronsPerPixelXY = 0.2497912;
micronsPerPixelZ = 0.25;
XYpix = 2816;
COM_pix = COM;
COM_pix(:,1) = COM_pix(:,1) / micronsPerPixelXY;
COM_pix(:,2) = COM_pix(:,2) / micronsPerPixelXY;
COM_pix(:,3) = round(COM_pix(:,3));
puncta_ordered = zeros(size(COM_pix));
z=1;
for i=1:L
    blank = zeros(XYpix,XYpix);
    h=imagesc(blank);
    hold('on');
    punctaInPlane = find(COM_pix(:,3) == i);
    for j=1:length(punctaInPlane)
        %text(COM_pix(punctaInPlane(j), 1), COM_pix(punctaInPlane(j), 2), num2str(z), 'color', 'white');
        blank(round(COM(punctaInPlane(j), 1)), round(COM(punctaInPlane(j), 2))) = 1;
        puncta_ordered(z,:) = [COM_pix(punctaInPlane(j), 1), COM_pix(punctaInPlane(j), 2), i];
        z=z+1;
    end    
    imwrite(blank, ['punctaFrame_' num2str(i) '.tif']);
end
save('puncta_ordered_vals', puncta_ordered);

