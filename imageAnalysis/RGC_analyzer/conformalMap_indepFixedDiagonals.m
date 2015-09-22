function mappedPositions = conformalMap_indepFixedDiagonals(mainDiagDist,skewDiagDist,xpos,ypos,VZmesh)
% implements quasi-conformal mapping suggested in
% Levy et al., 'Least squares conformal maps for automatic texture atlas generation', 2002, ACM Transactions on Graphics
M = size(VZmesh,1); N = size(VZmesh,2);
col1 = kron([1;1],[1:M-1]');
temp1 = kron([1;M+1],ones(M-1,1));
temp2 = kron([M+1;M],ones(M-1,1));
oneColumn = [col1 col1+temp1 col1+temp2];
% every pixel is divided into 2 triangles
triangleCount = (2*M-2)*(N-1);
vertexCount = M*N;
triangulation = zeros(triangleCount, 3);
% store the positions of the vertices for each triangle - triangles are oriented consistently
for kk = 1:N-1
  triangulation((kk-1)*(2*M-2)+1:kk*(2*M-2),:) = oneColumn + (kk-1)*M;
end
Mreal = sparse([],[],[],triangleCount,vertexCount,triangleCount*3);
Mimag = sparse([],[],[],triangleCount,vertexCount,triangleCount*3);
% calculate the conformality condition (Riemann's theorem)
for triangle = 1:triangleCount
  for vertex = 1:3
    nodeNumber = triangulation(triangle,vertex);
    xind = rem(nodeNumber-1,M)+1;
    yind = floor((nodeNumber-1)/M)+1;
    trianglePos(vertex,:) = [xpos(xind) ypos(yind) VZmesh(xind,yind)];
  end
  [w1,w2,w3,zeta] = assignLocalCoordinates(trianglePos);
  denominator = sqrt(zeta/2);
  Mreal(triangle,triangulation(triangle,1)) = real(w1)/denominator;
  Mreal(triangle,triangulation(triangle,2)) = real(w2)/denominator;
  Mreal(triangle,triangulation(triangle,3)) = real(w3)/denominator;
  Mimag(triangle,triangulation(triangle,1)) = imag(w1)/denominator;
  Mimag(triangle,triangulation(triangle,2)) = imag(w2)/denominator;
  Mimag(triangle,triangulation(triangle,3)) = imag(w3)/denominator;
end
% minimize the LS error due to conformality condition of mapping triangles into triangles
% take the two fixed points required to solve the system as the corners of the main diagonal
mainDiagXdist = mainDiagDist*M/sqrt(M^2+N^2); mainDiagYdist = mainDiagXdist*N/M;
A = [Mreal(:,2:end-1) -Mimag(:,2:end-1); Mimag(:,2:end-1) Mreal(:,2:end-1)];
b = -[Mreal(:,[1 end]) -Mimag(:,[1 end]); Mimag(:,[1 end]) Mreal(:,[1 end])]*[[xpos(1);xpos(1)+mainDiagXdist];[ypos(1);ypos(1)+mainDiagYdist]];
mappedPositions1 = A\b;
mappedPositions1 = [[xpos(1);mappedPositions1(1:end/2);xpos(1)+mainDiagXdist] [ypos(1);mappedPositions1(1+end/2:end);ypos(1)+mainDiagYdist]];
% take the two fixed points required to solve the system as the corners of the skew diagonal
skewDiagXdist = skewDiagDist*M/sqrt(M^2+N^2); skewDiagYdist = skewDiagXdist*N/M; freeVar = [[1:M-1] [M+1:M*N-M] [M*N-M+2:M*N]];
A = [Mreal(:,freeVar) -Mimag(:,freeVar); Mimag(:,freeVar) Mreal(:,freeVar)];
b = -[Mreal(:,[M M*N-M+1]) -Mimag(:,[M M*N-M+1]); Mimag(:,[M M*N-M+1]) Mreal(:,[M M*N-M+1])]*[[xpos(1)+skewDiagXdist;xpos(1)];[ypos(1);ypos(1)+skewDiagYdist]];
mappedPositions2 = A\b;
mappedPositions2 = [[mappedPositions2(1:M-1);xpos(1)+skewDiagXdist;mappedPositions2(M:M*N-M-1);xpos(1);mappedPositions2(M*N-M:end/2)] ...
                    [mappedPositions2(1+end/2:M-1+end/2);ypos(1);mappedPositions2(end/2+M:end/2+M*N-M-1);ypos(1)+skewDiagYdist;mappedPositions2(end/2+M*N-M:end)]];
% take the mean of the two independent solutions and return it as the solution
mappedPositions = (mappedPositions1+mappedPositions2)/2;

