function y = differenceOfGaussians_wOffset(x, offset, centerC, surroundC, centerSD, surroundSD)
%for fitting spotsMultiSize with a difference of cumulative gaussians for
%center and surround 
y = offset+centerC*(1-exp(-(x/2).^2 ./ (2*centerSD.^2))) - surroundC*(1-exp(-(x/2).^2 ./ (2*surroundSD^2)));


