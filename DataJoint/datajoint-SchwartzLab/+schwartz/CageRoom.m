%{
# the house has a house
-> schwartz.Cage
cage_move: date # when did the cage get to the new location? 
---
-> schwartz.Room  # room containing cage
 
%}

classdef CageRoom < dj.Part
    properties(SetAccess=protected)
         master = schwartz.Cage
     end
end

%implicit that the table defines a history of the cage location, with the
%present location being the one with the newest arrival_date