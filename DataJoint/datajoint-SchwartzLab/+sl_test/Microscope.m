%{
# Microscope 
scope_id : tinyint unsigned auto_increment
---
scope_name : varchar(32)                                       # name of scope
scope_location : enum('Schwartz lab', 'imaging core', 'other') # location 
notes: varchar(128)                                            # unstructured
%}

classdef Microscope < dj.Lookup
    
end
