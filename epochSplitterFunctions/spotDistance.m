function val = spotDistance(epoch)
[~, dist] = cart2pol(epoch.get('curShiftX'), epoch.get('curShiftY'));
val = round(dist);