function [Xpos, Ypos, D] = readSomaPositionsFromNetwork(Nfiles, midCell)
Xpos = zeros(Nfiles, 1);
Ypos = zeros(Nfiles, 1);
D = zeros(Nfiles, 1);
for i=1:Nfiles
   fname = sprintf('%.4d.dat',i);
   fid = fopen(fname, 'r');
   temp = str2num(fgetl(fid));
   Xpos(i) = temp(1);
   Ypos(i) = temp(2);
   fclose(fid);
end
midX = Xpos(midCell);
midY = Ypos(midCell);
for i=1:Nfiles
    D(i) = sqrt((Xpos(i) - midX)^2 + (Ypos(i) - midY)^2);    
end

dlmwrite('somaPositions.txt', [Xpos Ypos D]);

