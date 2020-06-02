function [] = readAllLinesFromNetwork(Nfiles)
allLinesX = []; %zeros(2, linesPerCell*Nfiles);
allLinesY = []; %zeros(2, linesPerCell*Nfiles);

z=1;
for i=1:Nfiles    
   fname = sprintf('%.4d.dat',i);
   fid = fopen(fname, 'r');    
   curLine = fgetl(fid);
   while(curLine>0);
       temp = str2num(curLine);
       allLinesX(1,z) = temp(1);
       allLinesX(2,z) = temp(3);
       allLinesY(1,z) = temp(2);
       allLinesY(2,z) = temp(4);       
       z=z+1;
       curLine = fgetl(fid);
   end
   fclose(fid);
end

dlmwrite('allLinesX.txt', allLinesX);
dlmwrite('allLinesY.txt', allLinesY);