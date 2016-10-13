

filterOn = {};
filterOff = {};


% polarity, delay, rise dur, hold dur, decay time constant
filtParams = cell(2);

% ON EX
filtParams{1,1} = [-1, .065, .016, 0, .03];

% ON IN
filtParams{2,1} = [1, .057, .03, .051, .055];

% OFF EX

% OFF IN

filters = cell(2);

% clf
% figure(55);
% ha = tight_subplot(2,1);

for vi = 1:2
    for oi = 1
        
        p = filtParams{vi,oi};
        delay = zeros(1, round(p(2) / sim_timeStep));
        rise = linspace(0, 1, round(p(3) / sim_timeStep));
        holds = ones(1, round(p(4) / sim_timeStep));
        decay = exp(-1 * (sim_timeStep:sim_timeStep:.3) / p(5));
        
        sig = horzcat(delay, rise, holds, decay) * p(1);
        sig(end+1) = 0;
        d = diff(sig);
        filters{vi,oi} = d;
        
        
%         axes(ha((oi - 1) * 2 + vi));
%         t = (1:length(sig)) * sim_timeStep;
%         plot(t, sig);
%         hold on
%         t = (1:length(lightResponses{vi,oi})) * .001;
%         r = lightResponses{vi,oi};
%         r = r - mean(r(1:20));
%         r = r / max(abs(r));
%         plot(t, r)
%         hold off
        
    end
end
c_filtersResampled = filters;