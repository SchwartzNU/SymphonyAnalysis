%{
# Electrophysiology rig 
rig_id : tinyint unsigned auto_increment
---
rig_name : varchar(32)                                       # name of rig
%}

classdef Rig < dj.Lookup
    
end
