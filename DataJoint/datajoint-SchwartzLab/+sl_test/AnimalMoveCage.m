%{
# animal has switched houses
-> sl_test.Animal
move_date: date                                                                     # date the move ocurred
move_from_cage_number: int unsigned          # from cage number
move_to_cage_number: int unsigned            # to cage number
---
cause = NULL : enum('weaning', 'set as breeder', 'experiment', 'crowding', 'other','unknown')     # cause of move
notes = NULL: varchar(128)                   # any extra notes
-> sl_test.User(moved_by='name')             # who did the move (we can have a User entry for CCM staff)
%}

classdef AnimalMoveCage < dj.Manual
end
