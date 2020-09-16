%{
# mouse has left the house
-> schwartz.Mouse
mouse_move: timestamp # when did the mouse wind up in this cage?
---
-> schwartz.Cage
%}

classdef MouseCaged < dj.Part %enter data manually
        properties(SetAccess=protected)
         master = schwartz.Mouse
     end
end

%implicit that the table defines a history of the cage location, with the
%present location being the one with the newest arrival_date