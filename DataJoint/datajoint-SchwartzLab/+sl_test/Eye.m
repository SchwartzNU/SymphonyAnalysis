%{
# Eye
-> sl_test.Animal
eye_id : tinyint unsigned
---
side: enum('L', 'R', 'Unknown')                 # left, right, or unknown
tags : longblob                 # struct with tags

%}

classdef Eye < dj.Manual
    
end