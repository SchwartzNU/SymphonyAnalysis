function [w1,w2,w3,zeta] = assignLocalCoordinates(triangle)
% triangle is a 3x3 matrix where the rows represent the x,y,z coordinates of the vertices.
% The local triangle is defined on a plane, where the first vertex is at the origin(0,0) and the second vertex is at (0,-d12).
d12 = norm(triangle(1,:)-triangle(2,:));
d13 = norm(triangle(1,:)-triangle(3,:));
d23 = norm(triangle(2,:)-triangle(3,:));
y3 = ((-d12)^2+d13^2-d23^2)/(2*(-d12));
x3 = sqrt(d13^2-y3^2); % provisional

w2 = -x3-i*y3; w1 = x3+i*(y3-(-d12));
zeta = i*(conj(w2)*w1-conj(w1)*w2); % orientation indicator
w3 = i*(-d12);
zeta = abs(real(zeta));
