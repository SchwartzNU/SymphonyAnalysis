function [DSI,OSI,DSang,OSang,Area,COM_length,COM_angle,Maj,Min,Poly] = dendritePolygonTracer(fname)

    M = imread(fname);
    image(M,'CDataMapping','scaled');
    colormap('gray');
    disp('Double click on the soma.');
    [x_soma, y_soma] = getpts(gcf);
    disp('Click on dendrite tips. Double click to finish.');
    [xpts, ypts] = getpts(gcf);
    Poly = cat(2,xpts,-ypts); %make polygon of the dendritic tree
    Poly = resamplePolygon(Poly,1000);
    Totpts = size(Poly,1);
    
    %Major and Minor Axes
    Length_Maj = pdist(Poly,'euclidean');
    [Maj, I_maj] = max(Length_Maj);
    count = ((Totpts^2 - Totpts)/2) - I_maj;
    %find major axis endpoints on polygon
    for i = 1:Totpts
        
        count_diff = count - ((i^2 - i)/2);
        count_rem = abs(rem(count_diff,i));
        if count_diff == 0
            ind_center1 = Totpts - i;
            ind_center2 = Totpts;
            break
        elseif count_diff <= 0
            ind_center1 = Totpts - i + 1;
            ind_center2 = ind_center1 + count_rem;
            break
        end
    end
    
    center = midPoint(Poly(ind_center1,:),Poly(ind_center2,:)); %find center of major axis
      
    Poly(:,1) = Poly(:,1) - center(1);
    Poly(:,2) = Poly(:,2) - center(2);
    Maj_axis = createLine(Poly(ind_center1,:),Poly(ind_center2,:));
    
    Min_axis = zeros((ind_center2 - ind_center1 - 1),4);
    Length_Min = zeros((ind_center2 - ind_center1 - 1),1);
    %find minor axis
    for j = 1:(ind_center2 - ind_center1 - 1)
        
        Min_axis(j,:) = orthogonalLine(Maj_axis,Poly((ind_center1 + j),:));
        Min_Pts = intersectLinePolygon(Min_axis(j,:),Poly);
        if size(Min_Pts,1) < 2
            Length_Min_temp = 0;
        else
            Length_Min_temp = pdist(Min_Pts,'euclidean');
            Length_Min(j) = max(Length_Min_temp);
        end
    end
    
    [Min,~] = max(Length_Min);
    
    [theta,rho] = cart2pol(Poly(:,1),Poly(:,2)); %rad
    
    figure
    drawPolygon(Poly(:,1), Poly(:,2), 'b-');
    
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
    
    %DS
    [x,y] = pol2cart(DSang*pi/180, max(rho)*DSI); %rad
    line([0 x], [0 y], 'Color', 'r');
    %OS
    [x,y] = pol2cart(OSang*pi/180, max(rho)*OSI); %rad
    line([-x x], [-y y], 'Color', 'g');
    
    %Area
    Area = abs(polygonArea(Poly));
    
    %Center of Mass Vector
    COM = centroid(Poly);
    %shift soma coordinates according to the new origin
    x_soma = x_soma - center(1);
    y_soma = y_soma + center(2);
    COM_length = sqrt((x_soma - COM(1))^2 + (y_soma - COM(2))^2);
    COM_angle = (atan((y_soma - COM(2))/(x_soma - COM(1))))*180/pi;
    line([x_soma COM(1)], [-y_soma COM(2)], 'Color', 'k')
    
    %Eccentricity
    %Ecc = sqrt(1 - (Min^2/Maj^2));
    %hold on
    %drawLine(Maj_axis,'Color','k');
    %drawLine(Min_axis(I_min,:),'Color','k');
  
end

