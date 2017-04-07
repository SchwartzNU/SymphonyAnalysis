figure(65);clf
opponency = (dtab.colorUVslope - dtab.colorGreenslope)./(dtab.colorUVslope + dtab.colorGreenslope);

uvnorm = abs(dtab.colorUVslope)./(abs(dtab.colorGreenslope) + abs(dtab.colorUVslope));
greennorm = abs(dtab.colorGreenslope)./(abs(dtab.colorGreenslope) + abs(dtab.colorUVslope));
opponent = sign(dtab.colorGreenslope) ~= sign(dtab.colorUVslope) & dtab.colorGreenslope ~= 0 & dtab.colorUVslope ~= 0;


hold on
quiver(-dtab.location_x(opponent), dtab.location_y(opponent), greennorm(opponent), uvnorm(opponent), .4, 'MarkerEdgeColor','r')
quiver(-dtab.location_x(~opponent), dtab.location_y(~opponent), greennorm(~opponent), uvnorm(~opponent), .4, 'MarkerEdgeColor','b')


xlabel('X and green')
ylabel('Y and UV')
axis equal
% axis square

figure(66);clf;
colorSensitivityDirection = atan(abs(dtab.colorUVslope) ./ abs(dtab.colorGreenslope));
% colorSensitivityDirection(colorSensitivityDirection < 0) = colorSensitivityDirection(colorSensitivityDirection < 0) + 2*pi;
colorSensitivityDirection = colorSensitivityDirection ./ (pi/2);

plot(dtab.location_y(~opponent), colorSensitivityDirection(~opponent), 'o', 'MarkerEdgeColor','b')
hold on
plot(dtab.location_y(opponent), colorSensitivityDirection(opponent), 'o', 'MarkerEdgeColor','r')
xlabel('Y position')
ylabel('UV sensitivity : green sensitivity angle normalized')