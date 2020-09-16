%{
# mouse house is now a home
-> schwartz.Mouse
---
-> schwartz.Project
reserved_time = CURRENT_TIMESTAMP : timestamp #when did the mouse move to this project?

%}

classdef MouseReserved < dj.Manual
end
