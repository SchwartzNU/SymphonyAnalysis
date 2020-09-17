%{
# Neuron (though we include RPE cells in here and maybe some glial types or pericytes)
cell_id: varchar(64) #cell id, like 040518Ac1, ...
                     #defaults to ch1, but could include -ch2 or multiple
                     #cells separated by commas
-> sl_test.Animal
---
-> sl_test.CellType             # cell type
tags : longblob                 # struct with tags

%}

classdef Neuron < dj.Manual
    
end
