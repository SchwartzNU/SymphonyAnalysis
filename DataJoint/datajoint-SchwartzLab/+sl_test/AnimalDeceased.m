%{
# mouse has left the house
-> sl_test.Animal
---
dod: date                                            # date of death
cause = NULL : enum('sacrificed','other','unknown')  # cause of death
-> sl_test.User(sacrificed_by='name')                # who did the deed

%}

classdef AnimalDeceased < dj.Manual
end

