function val = spotAngle(epoch)
[angle, ~] = cart2pol(epoch.get('curShiftX'), epoch.get('curShiftY'));
val = round(rad2deg(angle));