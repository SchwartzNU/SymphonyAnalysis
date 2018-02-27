function [angle,length,dist,slope] = dendritefananalysis(fname,sampling_factor)
    
    M = imread(fname);
    image(M);
    colormap('gray');
    disp('Double click on the soma.');
    [x_soma, y_soma] = getpts(gcf);
    Soma = [x_soma, y_soma];
    disp('Click on dendrite tips. Double click to finish.');
    [xpts, ypts] = getpts(gcf);
    Poly = cat(2,xpts,ypts); %make polygon of the dendritic tree
    Poly = resamplePolygon(Poly,1000);
    COM = centroid(Poly);
    dy = Soma(2) - COM(2);
    dx = Soma(1) - COM(1);
    COM_angle = (atan(dy/dx))*180/pi;
    
    %Center line from soma to COM
    centerLine = createLine(Soma(1),Soma(2),dx,dy);
    centerLineEnds = intersectLinePolygon(centerLine,Poly);
    
    %Points along center line for calculating fan angles
    X_pos = linspace(centerLineEnds(1,1),centerLineEnds(2,1),sampling_factor);
    Y_pos = linspace(centerLineEnds(1,2),centerLineEnds(2,2),sampling_factor);
    angle = zeros(sampling_factor,1);
    dist = zeros(sampling_factor,1);
    length = zeros(sampling_factor,1);
    
    figure;
    drawPolygon(Poly,'b-');
    line([centerLineEnds(1,1) centerLineEnds(2,1)],[centerLineEnds(1,2) centerLineEnds(2,2)],'Color','k');
    %Calculate fan angles
    for i = 1:sampling_factor
        
        pt = [X_pos(i) Y_pos(i)];
        orthLine = createLine(X_pos(i),Y_pos(i),-dy,dx);
        orthLineEnds = intersectLinePolygon(orthLine,Poly);
        angle(i,:) = angle3Points(orthLineEnds(1,:),Soma,orthLineEnds(2,:))*(180/pi);
        angle(i,:) = mod(angle(i,:),180);
        dist(i,:) = distancePoints(Soma,pt);
        length(i,:) = distancePoints(orthLineEnds(1,:),orthLineEnds(2,:));
        line(orthLineEnds(:,1),orthLineEnds(:,2),'Color','g');
        %keyboard;
        
    end
    
    figure
    plot(dist,angle);
    xlabel('Distance from soma (pixels)');
    ylabel('Angle (degrees)');
    
    figure
    plot(dist,length);
    xlabel('Distance from soma (pixels)');
    ylabel('Dendritic fan length (pixels)');
    
    slope = (length(2) - length(1))/(dist(2) - dist(1));
   
end
    