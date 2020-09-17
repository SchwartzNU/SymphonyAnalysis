%{
-> sl_test.Eye
image_id : tinyint unsigned     #unique image id
---
fname : varchar(128)            # image file name
notes = NULL : varchar(256)     # image notes
scaleX : float                  # microns per pixel X
scaleY : float                  # microns per pixel Y
optic_disc_X : int unsigned     # pixel location of optic disc X
optic_disc_Y : int unsigned     # pixel location of optic disc 
image_data : longblob           # image pixel matrix (x,y,colorChannels)
-> sl_test.ImageChannelMap      # color and meaning of each channel
cell_locations : longblob       # location of each counted soma (pixels)
cell_sizes : longblob           # area of each counted soma (pixels)
cell_intensities : longblob     # intensity of each counted soma
orientation : enum('Ventral down', 'Unknown') #orientation of retina
-> sl_test.User(imaged_by='name') # who did the imaging
tags : longblob                 # struct with tags

%}

classdef FullRetinaImage < dj.Manual
    
end