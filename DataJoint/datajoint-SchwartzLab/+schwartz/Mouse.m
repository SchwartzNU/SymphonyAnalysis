%{
# mouse
mouse_id: smallint unsigned                # unique mouse id
---
-> schwartz.Genotype        # genotype of mouse

dob: date                      # mouse date of birth
sex: enum('Male', 'Female', 'Unknown')       # sex of mouse - Male, Female, or Unknown/Unclassified
punch = NULL : enum('LL','RR','LR','RL') # earpunch

%}

classdef Mouse < dj.Manual
end
