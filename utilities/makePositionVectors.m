function [x_vect,y_vect]=makePositionVectors(x,y,ang,eye)

    %makes a line vector for the DS/OS cell centered around (x,y)
    %Intialize
    i = length(x);
    j = length(y);
    x_vect = zeros(i,2);
    y_vect = zeros(j,2);
    s1 = 'Right';
    s2 = 'Left';
    ang = mod((ang.*pi/180),(2*pi));   %convert to radians in (0,360) range
    if (i==j)
        %Compare with input
        if (strcmpi(s1,eye)==1)
            
            for k=1:i
                %calculate vector end points
                x_vect(k,1) = x(k) + (200*cos(ang(k)));
                x_vect(k,2) = x(k) - (200*cos(ang(k)));
                y_vect(k,1) = y(k) + (200*sin(ang(k)));
                y_vect(k,2) = y(k) - (200*sin(ang(k)));
            end
        end

        if (strcmpi(s2,eye)==1)
            
            for k=1:i
                %calculate vector end points
                x_vect(k,1) = -x(k) - (200*cos(ang(k)));
                x_vect(k,2) = -x(k) + (200*cos(ang(k)));
                y_vect(k,1) = y(k) + (200*sin(ang(k)));
                y_vect(k,2) = y(k) - (200*sin(ang(k)));
                
            end
        end
    end
    
    if(i~=j)
                
        disp('Error: Abcissae and Ordinates must be of equal length!');
    end
    
    %x_vect = x_vect.';
    %y_vect = y_vect.';
end           