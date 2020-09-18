%{
# just handling mice to get them used to humans
-> sl_test.AnimalEvent                               # includes date
---
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes: varchar(256)                                  # notes about the animal's state and comfort level
-> sl_test.User(handled_by='name')                   # who did it
%}

classdef AnimalEvent_Handling < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end

