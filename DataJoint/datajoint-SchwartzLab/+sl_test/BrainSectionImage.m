%{
-> sl_test.Animal
image_id : int     #unique image id
---
section_orientation : enum('Coronal', 'Horizontal', 'Sagittal') # orientation of section
section_coord : float # bregma, lambda, etc.
notes = NULL : varchar(256)
%}

classdef BrainSectionImage < dj.Manual
    
end