%{
# PSTH computation parameters
param_set_name : varchar(64)         # name of param set 
---
psth_bin : int unsigned              # units of ms
baseline_subtract : tinyint unsigned # 0 false or 1 true
gauss_win : int unsigned             # gaussian smoothing window (ms), 0 for none
sliding_win : int unsigned           # sliding average smoothing window (ms), 0 for none
%}

classdef PSTHParamSet < dj.Lookup
    
end

% could add optional Gaussian smoothing here too