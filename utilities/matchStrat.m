function [bestShift, fitVec, stratY_interp] = matchStrat(stratX, stratY, templates_x, templates, shiftAllowance)

N_templates = height(templates);

stratY_interp = interp1(stratX, stratY, templates_x);

fitVec = zeros(N_templates,1);
bestShift = zeros(N_templates,1);

x_step = abs(templates_x(2) - templates_x(1));

shiftAllowance_steps = round(shiftAllowance ./ x_step);

for i=1:N_templates
    bestFit = 0;
    bestShift_cur = 0;
    sum_sqared_data = sum((stratY_interp - mean(stratY_interp)).^2);
    
    for j=-shiftAllowance_steps:shiftAllowance_steps
        data_shifted = circshift(stratY_interp, j);
        
        fitVal = 1 - sum((data_shifted - templates.strat_mean{i}).^2) / sum_sqared_data;       
        
        if fitVal > bestFit
            bestFit = fitVal;
            bestShift_cur = j;
        end
    end
    bestShift(i) = bestShift_cur;
    fitVec(i) = bestFit;
end
