filename = '26079.stl';
Res = 150; %nm

[stlcoords] = READ_stl(filename,'binary');
xco = squeeze(stlcoords(:,1,:))';
yco = squeeze(stlcoords(:,2,:))';
zco = squeeze(stlcoords(:,3,:))';



Ymin = min(xco, [], 'all');
Xmin = min(yco, [], 'all');
Zmin = min(zco, [], 'all');
Ymax = max(xco, [], 'all');
Xmax = max(yco, [], 'all');
Zmax = max(zco, [], 'all');

XVox = round((Xmax - Xmin)/Res);
YVox = round((Ymax - Ymin)/Res);
ZVox = round((Zmax - Zmin)/Res);

%Voxelise the STL:
[OUTPUTgrid] = VOXELISE(YVox,XVox,ZVox,filename);

% %Create buffer on X dimension
% SetMinX = 10000;
% SetMinY = 10000;
% SetMinZ = 10000;
% SetMaxX = 35000;
% SetMaxY = 35000;
% SetMaxZ = 35000;
%
% Xprebuffer = round((Xmin - SetMinX)/Res);
% Xpostbuffer = round((SetMaxX-SetMinX)/Res) - Xprebuffer - XVox;
% 
% Yprebuffer = round((Ymin - SetMinY)/Res);
% Ypostbuffer = round((SetMaxY-SetMinY)/Res) - Yprebuffer - YVox;
% 
% XprebuffMatrix = zeros(length(OUTPUTgrid(:,1,1)), Xprebuffer, length(OUTPUTgrid(1,1,:)));
% XpostbuffMatrix = zeros(length(OUTPUTgrid(:,1,1)), Xpostbuffer, length(OUTPUTgrid(1,1,:)));
% OUTPUTgrid = cat(2, XprebuffMatrix, OUTPUTgrid, XpostbuffMatrix);
% 
% %Create buffer on Y dimension
% 
% 
% YprebuffMatrix = zeros(Yprebuffer, length(OUTPUTgrid(1,:,1)), length(OUTPUTgrid(1,1,:)));
% YpostbuffMatrix = zeros(Ypostbuffer, length(OUTPUTgrid(1,:,1)), length(OUTPUTgrid(1,1,:)));
% OUTPUTgrid = cat(1, YprebuffMatrix, OUTPUTgrid, YpostbuffMatrix);
% 
% %Create buffer on Z dimension
% Zprebuffer = round((Zmin - SetMinZ)/Res);
% Zpostbuffer = round((SetMaxZ-SetMinZ)/Res) - Zprebuffer - ZVox;
% 
% ZprebuffMatrix = zeros(length(OUTPUTgrid(:,1,1)), length(OUTPUTgrid(1,:,1)), Zprebuffer);
% ZpostbuffMatrix = zeros(length(OUTPUTgrid(:,1,1)), length(OUTPUTgrid(1,:,1)), Zpostbuffer);
% OUTPUTgrid = cat(3, ZprebuffMatrix, OUTPUTgrid, ZpostbuffMatrix);

OUTPUTgrid = permute(OUTPUTgrid,[3,2,1]);

newFilename = [erase(filename, '.stl'), '.tif'];
imwrite(OUTPUTgrid(:,:,1), newFilename, 'compression','none')
for i = 2:length(OUTPUTgrid(1,1,:))
	imwrite(OUTPUTgrid(:,:,i), newFilename, 'WriteMode', 'append', 'compression','none')
end
