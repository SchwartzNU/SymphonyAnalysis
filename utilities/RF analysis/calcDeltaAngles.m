function deltaAngles = calcDeltaAngles(X, Y, angles)
deltaAngles =  angles - atan(Y ./ X);
deltaAngles = deltaAngles * 180/pi; %Convert to degrees
deltaAngles = wrapTo360(deltaAngles);
wrapInd = find(deltaAngles > 180);
deltaAngles(wrapInd) = 360 - deltaAngles(wrapInd);
wrapInd = find(deltaAngles > 90);
deltaAngles(wrapInd) = 180 - deltaAngles(wrapInd);
end