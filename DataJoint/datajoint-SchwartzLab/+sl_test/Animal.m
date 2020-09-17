%{
# animal
animal_id: int unsigned                         # unique animal id
id_type = 'default' : enum('default', 'tagged', 'untagged') # default is for old data where we don't really know the birth date
species = 'Lab mouse' : varchar(64)              # species
---
-> sl_test.Genotype                             # genotype of animal
dob = NULL : date                               # mouse date of birth
sex: enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = NULL : enum('LL','RR','LR','RL')        # earpunch
tags : longblob                                 # struct with tags
born_in_cage_number = NULL : int unsigned       # cage number in which animal was born
%}

classdef Animal < dj.Manual
    methods
        function answer = isAlive(key) %is key automatic here?
            answer = true;
        end
    end
end


