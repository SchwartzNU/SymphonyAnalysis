%{
 # a list of mice and their current cages
 -> schwartz.Mouse # one entry per mouse
---
-> schwartz.MouseCaged
-> schwartz.Cage


%}

classdef MouseCurrent < dj.Computed
    properties (Dependent)
        keySource
    end
    methods (Access=protected)
        function makeTuples(self,key)
            [key.cage_id,key.cage_date] = fetch1(schwartz.MouseCaged & sprintf('mouse_id=%d',key.mouse_id),'cage_id','cage_date','ORDER BY cage_date DESC LIMIT 1');
%             if isempty(cages)
%                 key.cage_id='';
%                 key.cage_date='';
% %             else
%                 key.cage_id = cages{1};
%                 key.cage_date = dates{1};
%             end
            self.insert(key);
        end
    end
       methods 
        function source = get.keySource(obj)
            source = schwartz.Mouse & schwartz.MouseCaged - schwartz.MouseDeceased; %iterates through all living mice associated with a cage at any point
        end
    end
end

