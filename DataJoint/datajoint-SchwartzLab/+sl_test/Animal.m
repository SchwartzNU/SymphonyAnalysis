%{
# animal
animal_id: int unsigned                         # unique animal id
---
species = 'LabMouse' : varchar(64)              # species
-> sl_test.Genotype                             # genotype of animal
dob = NULL : date                               # mouse date of birth
sex: enum('Male', 'Female', 'Unknown')          # sex of mouse - Male, Female, or Unknown/Unclassified
punch = NULL : enum('LL','RR','LR','RL')        # earpunch
tags : longblob                                 # struct with tags
born_in_cage_number: int unsigned               # cage number in which animal was born
%}

classdef Animal < dj.Manual
end


%-> sl_test.EventLog                             # log of events (cage change, breeding, weaning, tamoxifen, sacrifice, behavioral session, etc.)
