function [respRange, selectivityRange, resp_norm, slope_norm] = responseAndSelectivityRangeFromHillFunc(base, maxVal, rate, xhalf, respThres, selectivityThres)

    Xvals = 0:.01:1;

    resp = base + (maxVal-base) ./ (1 + (xhalf ./ Xvals).^rate);
    slope = -(rate .* (base - maxVal) .* (xhalf./Xvals).^rate) ./ ...
        (Xvals .* ( (xhalf./Xvals).^rate + 1).^2);
    
    resp_norm = resp ./ maxVal;
    slope_norm = slope ./ maxVal; %now in fractional change per contrast   
    
    respRange = Xvals(resp_norm > respThres);
    %selectivityRange = Xvals(find(resp_norm > respThres & resp_norm < selectivityThres));
    selectivityRange = Xvals(slope_norm > selectivityThres);

%     respRange(1)
%     respRange(end)
%     
%     selectivityRange(1)
%     selectivityRange(end)
%     
       figure;
       plot(Xvals, resp_norm, 'b');
       hold on;
       plot(Xvals, slope_norm, 'r');
end

