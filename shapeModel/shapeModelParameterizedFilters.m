
% polarity, delay, rise dur, hold dur, decay time constant, baseline to peak ratio
filtParams = cell(2);

% ON EX
% filtParams{1,1} = [-1, .065, .016, 0, .03]; % 060216Ac2
filtParams{1,1} = [-1, .175, .05, 0, .08, 0];% 010716Ac1

% paramValues(paramSetIndex,col_filterDelay)

% ON IN
% filtParams{2,1} = [1, .057, .08, .13, .1, .4]; % 060216Ac2
filtParams{2,1} = [1, .14, .08, .08, .3, 0]; % 010716Ac1


% OFF EX
filtParams{1,2} = [-1, .065, .016, 0, .03, 0];

% OFF IN
filtParams{2,2} = [1, .057, .03, .051, .055, 0];


filters = cell(2);

plotFilters = false;
if plotFilters
    clf
    figure(55);
    ha = tight_subplot(2,2);
end

for vi = 1:2
    for oi = 1:2
        if ~useOffFilters && oi == 2
            filters{vi,oi} = 0;
            continue
        end
        
        
        p = filtParams{vi,oi};
        delay = zeros(1, round(p(2) / sim_timeStep));
        rise = linspace(0, 1, round(p(3) / sim_timeStep));
        holds = ones(1, round(p(4) / sim_timeStep));
        decay = (1-p(6))*exp(-1 * (sim_timeStep:sim_timeStep:2) / p(5)) + p(6);
        
        sig = horzcat(delay, rise, holds, decay) * p(1);
%         sig(end+1) = 0;
        d = diff(sig);
        filters{vi,oi} = d;
        
        if plotFilters
            axes(ha((oi - 1) * 2 + vi));
            t = (1:length(sig)) * sim_timeStep;
            plot(t, sig);
            hold on
            t = (1:length(lightResponses{vi,oi})) / 10000 - .5;
            r = lightResponses{vi,oi};
            r = r - mean(r(1:2500));
            r = r / prctile(abs(r(1:10000)), 98);
            plot(t, r)
            hold off
        end
        
    end
end
c_filtersResampled = filters;