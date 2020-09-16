%{
# CellImage
-> sl_test.Neuron
image_id : int     #unique image id
---
imageType : enum('2P', 'Confocal') # type of image
fname : varchar(128) #image file name
%}

classdef CellImage < dj.Manual
    
end
