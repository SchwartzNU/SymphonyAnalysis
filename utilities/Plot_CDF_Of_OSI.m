function [OSICells, OSI, OSAng] = Plot_CDF_Of_OSI(OSI_DG_non_ODB,OSI_DG_ODB,OSI_FB_non_ODB,OSI_FB_ODB)

[h_FB,p_FB] = kstest2(OSI_FB_non_ODB,OSI_FB_ODB);
[h_DG,p_DG] = kstest2(OSI_DG_non_ODB,OSI_DG_ODB);



figure
subplot(1,2,1)
cdfplot(OSI_FB_ODB)
hold on
cdfplot(OSI_FB_non_ODB)

title({'Flashed Bars' ; ['p = ' num2str(p_FB)]})
xlabel('OSI')
legend(['ODB: Mean = ' num2str(mean(OSI_FB_ODB))], ['non-ODB: Mean = ' num2str(mean(OSI_FB_non_ODB))])


subplot(1,2,2)
cdfplot(OSI_DG_ODB)
hold on
cdfplot(OSI_DG_non_ODB)

legend(['ODB: Mean = ' num2str(mean(OSI_FB_ODB))], ['non-ODB: Mean = ' num2str(mean(OSI_FB_non_ODB))])
title({'Drifting Gratings' ; ['p = ' num2str(p_DG)]})
xlabel('OSI')

end