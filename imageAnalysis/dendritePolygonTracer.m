function [DSI, OSI, DSang, OSang, area, centroidX, centroidY] = dendritePolygonTracer(fname)
    M = imread(fname);
    image(M);
    colormap('gray');    
    disp('Click on dendrite tips. Double click to finish.');
    [xpts, ypts] = getpts(gcf);
    %centerPoint
    disp('Double click on soma.');
    [centerX, centerY] = getpts(gcf);
    xpts = xpts - centerX;
    ypts = ypts - centerY;
    
    [theta,rho] = cart2pol(xpts,ypts); %rad
    
    %DSI and OSI
    R=0;
    RDirn=0;
    ROrtn=0;    
    for j=1:length(theta)
        R=R+rho(j);
        RDirn = RDirn + rho(j)*exp(sqrt(-1)*theta(j));
        ROrtn = ROrtn + rho(j)*exp(2*sqrt(-1)*theta(j));
    end
    
    DSI = abs(RDirn/R);
    OSI = abs(ROrtn/R);
    DSang = angle(RDirn/R)*180/pi; %deg
    OSang = angle(ROrtn/R)*90/pi; %deg
    
    if DSang < 0
        DSang = DSang + 360;
    end
    if OSang < 0
        OSang = OSang + 360;
    end
    
    hold('on');
    plot(xpts+centerX, ypts+centerY, 'c-');
    %DS
    [x,y] = pol2cart(DSang*pi/180, max(rho)*DSI); %rad
    x = x+centerX;
    y = y+centerY;
    line([centerX x], [centerY y], 'Color', 'r');
    %OS
    [x,y] = pol2cart(OSang*pi/180, max(rho)*OSI); %rad
    x = x+centerX;
    y = y+centerY;
    line([centerX x], [centerY y], 'Color', 'g');
    
    %Area
    area = polyarea(xpts,ypts);
    
    %Center of Mass
    centroidX = mean(xpts);
    centroidY = mean(ypts);
  
end

