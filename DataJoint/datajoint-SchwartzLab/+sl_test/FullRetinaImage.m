%{
-> sl_test.Eye
image_id : tinyint unsigned     #unique image id
---
fname : varchar(128)            # root image file name
notes = NULL : varchar(256)     # image notes
-> sl_test.ImageChannelMap      # color and meaning of each channel
-> sl_test.Microscope           # scope on which image was taken
orientation : enum('Ventral down', 'Unknown') #orientation of retina
-> sl_test.User(imaged_by='name') # who did the imaging
scaleX : float                  # microns per pixel X
scaleY : float                  # microns per pixel Y
scaleZ : float                  # microns per pixel Z (0 if 2D image)
%}

classdef FullRetinaImage < dj.Manual
    
end

% This all belongs in an analysis class 
%
% optic_disc_X : int unsigned     # pixel location of optic disc X
% optic_disc_Y : int unsigned     # pixel location of optic disc 
% cell_locations : longblob       # location of each counted soma (pixels)
% cell_sizes : longblob           # area of each counted soma (pixels)
% cell_intensities : longblob     # intensity of each counted soma
% tags : longblob                 # struct with tags