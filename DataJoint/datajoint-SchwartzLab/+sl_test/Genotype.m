%{
 # Genotype of the animal
 genotype_name : varchar(64)          # the name of this genotype
 ---
 description = NULL : varchar(128)    # explanation of this genotype
 tags : longblob                 # struct with tags

%}
classdef Genotype < dj.Lookup
    
end