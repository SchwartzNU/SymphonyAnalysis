%{
# mouse has left the house
-> schwartz.Mouse
---
dod: date    # mouse date of death
cause = NULL : enum('sacrificed','other','unknown')  #cause of death

%}

classdef MouseDeceased < dj.Manual
end

%alive: enum('Y','N')        # is mouse alive??
