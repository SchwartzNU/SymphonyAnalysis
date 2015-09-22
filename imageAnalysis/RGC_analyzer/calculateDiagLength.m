function [mainDiagDist, skewDiagDist] = calculateDiagLength(xpos,ypos,VZmesh)
M = size(VZmesh,1); N = size(VZmesh,2);
[ymesh,xmesh] = meshgrid(ypos,xpos);
mainDiagDist = 0; skewDiagDist = 0;
% travel on the diagonals and not necessarily the grid points) and accumulate the 3d distance traveled
if N >= M
  xKnots = interp2(ymesh,xmesh,xmesh, ypos, [xpos(1):(xpos(end)-xpos(1))/(N-1):xpos(end)]');
  yKnots = interp2(ymesh,xmesh,ymesh, ypos, [xpos(1):(xpos(end)-xpos(1))/(N-1):xpos(end)]');
  zKnotsMainDiag = griddata(xmesh(:),ymesh(:),VZmesh(:), [xpos(1):(xpos(end)-xpos(1))/(N-1):xpos(end)]', ypos');
  zKnotsSkewDiag = griddata(xmesh(:),ymesh(:),VZmesh(:), [xpos(1):(xpos(end)-xpos(1))/(N-1):xpos(end)]', ypos(end:-1:1)');
  for kk = 1:N-1
    mainDiagDist = mainDiagDist + sqrt((xKnots(kk,kk)-xKnots(kk+1,kk+1))^2 + (yKnots(kk,kk)-yKnots(kk+1,kk+1))^2 + (zKnotsMainDiag(kk)-zKnotsMainDiag(kk+1))^2);
    skewDiagDist = skewDiagDist + sqrt((xKnots(kk,N+1-kk)-xKnots(kk+1,N-kk))^2 + (yKnots(kk,N+1-kk)-yKnots(kk+1,N-kk))^2 + (zKnotsSkewDiag(kk)-zKnotsSkewDiag(kk+1))^2);
  end
else
  xKnots = interp2(ymesh,xmesh,xmesh, [ypos(1):(ypos(end)-ypos(1))/(M-1):ypos(end)], xpos');
  yKnots = interp2(ymesh,xmesh,ymesh, [ypos(1):(ypos(end)-ypos(1))/(M-1):ypos(end)], xpos');
  zKnotsMainDiag = griddata(xmesh(:),ymesh(:),VZmesh(:), xpos', [ypos(1):(ypos(end)-ypos(1))/(M-1):ypos(end)]');
  zKnotsSkewDiag = griddata(xmesh(:),ymesh(:),VZmesh(:), xpos', [ypos(end):-(ypos(end)-ypos(1))/(M-1):ypos(1)]');
  for kk = 1:M-1
    mainDiagDist = mainDiagDist + sqrt((xKnots(kk,kk)-xKnots(kk+1,kk+1))^2 + (yKnots(kk,kk)-yKnots(kk+1,kk+1))^2 + (zKnotsMainDiag(kk)-zKnotsMainDiag(kk+1))^2);
    skewDiagDist = skewDiagDist + sqrt((xKnots(kk,M+1-kk)-xKnots(kk+1,M-kk))^2 + (yKnots(kk,M+1-kk)-yKnots(kk+1,M-kk))^2 + (zKnotsSkewDiag(kk)-zKnotsSkewDiag(kk+1))^2);
  end
end
