figure(65);clf
opponency = (dtab.colorUVslope - dtab.colorGreenslope)./(dtab.colorUVslope + dtab.colorGreenslope);

uvnorm = dtab.colorUVslope./(abs(dtab.colorGreenslope) + abs(dtab.colorUVslope));
greennorm = dtab.colorGreenslope./(abs(dtab.colorGreenslope) + abs(dtab.colorUVslope));
opponent = sign(dtab.colorGreenslope) ~= sign(dtab.colorUVslope) & dtab.colorGreenslope ~= 0 & dtab.colorUVslope ~= 0;


hold on
quiver(-dtab.location_x(opponent), dtab.location_y(opponent), greennorm(opponent), uvnorm(opponent), .4, 'MarkerEdgeColor','r')
quiver(-dtab.location_x(~opponent), dtab.location_y(~opponent), greennorm(~opponent), uvnorm(~opponent), .4, 'MarkerEdgeColor','b')


xlabel('X and green')
ylabel('Y and UV')
axis equal
% axis square