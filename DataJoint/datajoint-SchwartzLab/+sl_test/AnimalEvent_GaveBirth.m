%{
# babies!
-> sl_test.AnimalEvent(labor_day='date')             # date of labor
---
number_of_pups : tinyint unsigned                    # how many babies
%}

classdef AnimalEvent_GaveBirth < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end

