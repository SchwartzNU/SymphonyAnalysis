%{
# mouse has left the house
-> sl_test.AnimalEvent(dod='date')                   # date of death
---
cause = NULL : enum('sacrificed not needed','sacrificed for experiment','other','unknown')  # cause of death
-> sl_test.User(sacrificed_by='name')                # who did the deed (need to add empty user for this)

%}

classdef AnimalEvent_Deceased < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end

