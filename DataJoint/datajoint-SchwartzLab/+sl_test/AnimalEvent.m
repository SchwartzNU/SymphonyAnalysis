%{
# Any animal event
-> sl_test.Animal
event_id : smallint unsigned                              #unique event ID
---
date: date                                                #date of this event
%}

classdef AnimalEvent < dj.Manual
    
end

