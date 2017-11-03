function OSIPlotter(OSICells, LocData, LocCells, OSI, OSAng)
Gain = 1000;

hold on
%scatter(LocData(:,1),LocData(:,2))
plot([-2000;2000],[0; 0])
plot([0;0],[-2000;2000])
plot([-2000,-2000 + (2*Gain*.2)],[-2000,-2000],'b','LineWidth',2)

 for ii = 1:length(OSICells)
     for iii = 1:length(LocData)
         if contains(OSICells(ii), LocCells(iii))
             X(1) = LocData(iii,1) - Gain*OSI(ii)*cosd(OSAng(ii));
             Y(1) = LocData(iii,2) - Gain*OSI(ii)*sind(OSAng(ii));
             X(2) = LocData(iii,1) + Gain*OSI(ii)*cosd(OSAng(ii));
             Y(2) = LocData(iii,2) + Gain*OSI(ii)*sind(OSAng(ii));
             plot(X,Y)
             h = plot(X,Y,'k')
             set(h , 'LineWidth', 2)
         end
     end
 end 
end