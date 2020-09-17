%{
# eye injections
-> sl_test.Animal
-> sl_test.InjectionSubstance
-> sl_test.Eye
inject_date: date                    # date of injection
---
inject_time: time                    # time of day
dilution: float                      # dilution of substance
tags: longblog
notes: varchar(256)                  # injection notes (can include people who assisted)
-> sl_test.User(injected_by='name')  # who did the injection
%}

classdef EyeInjection < dj.Manual
    
end
