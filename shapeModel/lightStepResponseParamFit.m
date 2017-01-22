% solves parameters for fitting light step responses
% eid = 101;
% stepResponse = cellData.epochs(eid).getData('Amplifier_Ch1');

% function lightStepResponseParamFit(stepResponse, voltage, 

% stepResponse = meanData';
voltage = -60;
preTimeSec = cellData.epochs(eid).get('preTime') / 1000;
stepResponse = stepResponse - mean(stepResponse(1:(preTimeSec * 10000)));
stepResponse = stepResponse(1:10000 * 1.5);
stepResponse = stepResponse ./ prctile(abs(stepResponse), 99);
stepResponse = stepResponse ./ sign(voltage);
stepResponse = stepResponse(preTimeSec * 10000 : end);
r = resample(stepResponse, round(1/sim_timeStep), 10000);



% delay, rise dur, hold dur, decay time constant, baseline to peak ratio
x0 = [.05, .01, .02, .2, 0];
fToMin = @(p) mean(power(abs(makeParametricResponse(p, sim_timeStep, length(r)) - r), 2));


figure(10);clf;
hold on
plot(r)
plot(makeParametricResponse(x0, sim_timeStep, length(r)))

p = x0;
for i = 1:5
    [p, f] = fminsearch(fToMin, p);
end


plot(makeParametricResponse(p, sim_timeStep, length(r)))
hold off
legend('signal','initial','final')

function d = makeParametricResponse(p, sim_timeStep, len)

    delay = zeros(1, round(p(1) / sim_timeStep));
    rise = linspace(0, 1, round(p(2) / sim_timeStep));
    holds = ones(1, round(p(3) / sim_timeStep));
    decay = (1-p(5))*exp(-1 * (sim_timeStep:sim_timeStep:10) / p(4)) + p(5);
    
    sig = horzcat(delay, rise, holds, decay);
%     d = diff(sig);
    d = sig(1:len)';
    
end