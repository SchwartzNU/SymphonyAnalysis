%{
# Image of a brain section
-> sl_test.Animal
image_id : int unsigned    #unique image id
---
fname : varchar(128) #image file name
section_orientation : enum('Coronal', 'Horizontal', 'Sagittal') # orientation of section
section_coord : float             # bregma, lambda, etc.
notes = NULL : varchar(256)       # image notes
scaleX : float                    # microns per pixel X
scaleY : float                    # microns per pixel Y
image_data : longblob             # image pixel matrix (x,y,colorChannels)
-> sl_test.ImageChannelMap        # color and meaning of each channel
-> sl_test.User(imaged_by='name') # who did the imaging
-> sl_test.User(sliced_by='name') # who did the slice
tags : longblob                 # struct with tags

%}

classdef BrainSectionImage < dj.Manual
    
end