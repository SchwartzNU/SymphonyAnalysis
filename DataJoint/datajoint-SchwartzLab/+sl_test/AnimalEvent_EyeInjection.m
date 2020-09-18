%{
# eye injections
-> sl_test.AnimalEvent(inject_date='date')
---
-> sl_test.InjectionSubstance
-> sl_test.Eye
inject_time: time                    # time of day
dilution: float                      # dilution of substance
tags: longblog
notes: varchar(256)                  # injection notes (can include people who assisted)
-> sl_test.User(injected_by='name')  # who did the injection
%}

classdef AnimalEvent_EyeInjection < dj.Part
    properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end
