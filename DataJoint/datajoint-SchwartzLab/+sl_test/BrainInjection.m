%{
# injections
-> sl_test.Animal
-> sl_test.InjectionSubstance
inject_date: date                    # date of injection
target: varchar(32)                  # brain area targeted
hemisphere: enum('L', 'R')           # left or right side
---
inject_time: time                    # time of day
head_rotation : float                # degrees, if not straight down
coordinates: longblob                # 3 element vector of coordinates in the standard order
dilution: float                      # dilution of substance
tags: longblog
notes: varchar(256)                  # surgery notes
-> sl_test.User(injected_by='name')  # who did the injection
%}

classdef BrainInjection < dj.Imported
    
end
