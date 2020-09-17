%{
 # Genotype of the animal
 genotype_name : varchar(64)          # the name of this genotype
 ---
 description = NULL : varchar(128)    # explanation of this genotype (include information about whether it is inducible and by what means)
 tags : longblob                 # struct with tags

%}
classdef Genotype < dj.Lookup
    
end