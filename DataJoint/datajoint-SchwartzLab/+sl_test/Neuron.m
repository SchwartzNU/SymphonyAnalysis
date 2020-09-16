%{
# Neuron
cell_id: varchar(64) #cell id, like 040518Ac1, ...
                     #defaults to ch1, but could include -ch2 or multiple
                     #cells separated by commas
-> sl_test.Animal

---
%}

classdef Neuron < dj.Manual
    
end
