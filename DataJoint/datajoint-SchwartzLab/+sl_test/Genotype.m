 %{
 # Genotype of the animal
 genotype_name : varchar(64)          # the name of this genotype
 --- 
 description = NULL : varchar(128) #explanation of this genotype
%}
 classdef Genotype < dj.Lookup
 end