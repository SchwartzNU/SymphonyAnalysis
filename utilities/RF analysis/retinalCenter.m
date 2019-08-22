load('RF_dataTable.mat')

f = @centerValue;
x0 = [500,500];
options = optimset('Display', 'iter-detailed');

[bestX, lowestRatio] = fminsearch(f, x0, options);

function ratio = centerValue(x)
load('RF_dataTable.mat')
newX = dataTable.X_mirror + x(1);
newY = dataTable.Y + x(2);
deltaAngles = calcDeltaAngles(newX, newY, dataTable.Angle_mirror);
% numPerpendicular = length(find(deltaAngles >= 90 - 90/4));
% numParallel = length(find(deltaAngles <= 90/4));
% ratio = 10000 * numParallel / numPerpendicular;
ratio = 90 - mean(deltaAngles);
end