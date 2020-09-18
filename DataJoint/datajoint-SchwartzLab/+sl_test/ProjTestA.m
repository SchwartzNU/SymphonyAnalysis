%{
 # Projection test (temporary)
 prim_att : varchar(64)          # primary
 prim_num : int unsigned
 ---
 sec_att : varchar(64)
 sec_num : int unsigned
%}
classdef ProjTestA < dj.Lookup
    
end