%{
# like graduation for a mouse I guess
-> schwartz.Mouse
---
status: enum('carrier','noncarrier') #genetic status of animal

%}

classdef MouseGenotypeStatus < dj.Part %enter data manually
        properties(SetAccess=protected)
         master = schwartz.Mouse
     end
end
