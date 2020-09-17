%{
# brain injections
-> sl_test.AnimalEvent(inject_date='date')
---
-> sl_test.InjectionSubstance
target: varchar(32)                  # brain area targeted
hemisphere: enum('L', 'R')           # left or right side
inject_time: time                    # time of day
head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order
dilution: float                      # dilution of substance (or 0 if not applicable or non-diluted)
tags: longblog
notes = NULL: varchar(256)           # surgery notes (can include people who assisted)
-> sl_test.User(injected_by='name')  # who did the injection
%}

classdef AnimalEvent_BrainInjection < dj.Part
    properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end
