%{
# CellImage
-> sl_test.Neuron
image_id : int                    #unique image id
---
imageType : enum('2P', 'Confocal')# type of image
fname : varchar(128)              # image file name
trace_fname = NULL : varchar(128) # swc file
notes = NULL : varchar(256)       # image notes
scaleX : float                    # microns per pixel X
scaleY : float                    # microns per pixel Y
scaleZ : float                    # microns per pixel Z
image_data : longblob             # image pixel matrix (x,y,colorChannels)
max_proj_image_data : longblob    # maximum projection image pixel matrix (x,y) (possibly after trace and fill out)
stratification_data : longblob    # 2 columns, IPL depth and dendritic length 
-> sl_test.ImageChannelMap        # color and meaning of each channel
-> sl_test.User(imaged_by='name') # who did the imaging

%}

classdef CellImage < dj.Manual
    
end

%it would be nice to store trace in here somewhere