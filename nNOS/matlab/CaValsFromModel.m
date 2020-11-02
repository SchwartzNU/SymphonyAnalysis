function [Ca_mean_D, Ca_mean_L, Ca_med_D, Ca_med_L] = CaValsFromModel(allV_D, allV_L)
Ca_D = sum(sigmoid(allV_D, -29.57, 6.6));
Ca_L = sum(sigmoid(allV_L, -29.57, 6.6));
Ca_mean_D = mean(Ca_D);
Ca_mean_L = mean(Ca_L);
Ca_med_D = median(Ca_D);
Ca_med_L = median(Ca_L);