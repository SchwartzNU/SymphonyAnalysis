function vzmesh = fitSurfaceToSACAnnotation(annotationFilename)
% read the annotation file
[t1,t2,t3,t4,t5,x,y,z] = textread(annotationFilename, '%u%u%d%d%d%d%d%d','headerlines',1);
% point tool measures the pixel location and intensity
% Area Mean	Min	Max	X Y	Slice % area is 0 and min,mean,max are all same
% add 1 to x and z, butnot to y because FIJI point tool starts from 0 for pixels of an image
% but from 1 for slice of a stack
x=x+1; z=z+1;

% find the maximum boundaries
xMax = max(x); yMax = max(y);
% smoothened fit (with extrapolation) to a grid - to save time, make the grid coarser (every 3 pixels)
[zgrid,xgrid,ygrid] = gridfit(x,y,z,[[1:3:xMax-1] xMax],[[1:3:yMax-1] yMax],'smoothness',15);
% linearly (fast) interpolate to fine grid
[xi,yi]=meshgrid(1:xMax,1:yMax); xi = xi'; yi = yi';
vzmesh=interp2(xgrid,ygrid,zgrid,xi,yi,'*linear',mean(zgrid(:)));
% interp2: Interpolation for 2-D gridded data in meshgrid format
%basically takes the points and creates a plane...