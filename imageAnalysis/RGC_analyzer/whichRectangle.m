function ind = whichRectangle(vX, vY, x, y, w, h, resampleFactor, pixelRes_XY)
    pX = vX*resampleFactor - resampleFactor/2; %voxel to pixel
    pY = vY*resampleFactor - resampleFactor/2; %voxel to pixel
    pX = pX * pixelRes_XY; %pixel to micron
    pY = pY * pixelRes_XY;

    L = length(x);
    ind = []; %should only be 1
    for i=1:L-1
       if pX > x(i) && pX < x(i)+w(i) && pY > y(i) && pY < y(i)+h(i)
           ind = [ind i];
       end
           
    end
    if isempty(ind)
        ind = L;
    end
    
end
