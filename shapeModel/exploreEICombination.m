clf
x = [];
y = [];
for ci = 1:size(dtab,1)
    if ~strcmp(dtab{ci, 'cellType'}, 'ON WFDS')
        continue
    end
    
    
    ex = dtab{ci, 'SMS_charge_ex'}{1};
    in = dtab{ci, 'SMS_charge_inh'}{1};
    sp = dtab{ci, 'SMS_onSpikes'}{1};

    if isempty(ex) || isempty(in) || isempty(sp)
        continue
    end    
    if length(ex) ~= length(sp)
        continue
    end
    
    wc = ex(3:10) + in(3:10)/20;
    ca = sp(3:10);
    x = [x; wc];
    y = [y; ca];
    

end
plot(x, y, 'o')
xlabel('wc')
ylabel('sp')
p = polyfit(x,y,3);
k = polyval(p, sort(x));
hold on
plot(sort(x),k)