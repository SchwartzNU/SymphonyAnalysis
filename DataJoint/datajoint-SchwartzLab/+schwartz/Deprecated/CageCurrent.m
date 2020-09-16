%{
 # a list of cages and their current rooms
 -> schwartz.CageRoom #updates with cageroom
 
%}

classdef CageCurrent < dj.Computed
    properties (Dependent)
        keySource
    end
    methods (Access=protected)
        function makeTuples(self,key)
            %[key.arrival_date,key.location] = fetch1(schwartz.CageRoom & sprintf('cage_id="%s"',key.cage_id),'arrival_date','location','ORDER BY arrival_date DESC LIMIT 1');
            key.arrival_date = fetch1(schwartz.CageRoom & sprintf('cage_id="%s"',key.cage_id),'arrival_date','ORDER BY arrival_date DESC LIMIT 1');
            %if ~isempty(rooms)
            %    key.location = rooms{1};
            %end
            self.insert(key);
        end
    end
    
    methods 
        function source = get.keySource(obj)
            source = schwartz.Cage & schwartz.CageRoom;
        end
    end
end

%location = NULL : enum('SB-419','SB-427','SB-455')  # room containing cage