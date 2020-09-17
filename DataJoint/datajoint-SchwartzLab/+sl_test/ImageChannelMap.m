%{
# Color channel map for image
image_channel_map_id : int unsigned
---
N_channels : tinyint unsigned 
ch1_color : varchar(16)     # green, yellow, red, cyan, etc.
ch1_label : varchar(32)     # molecule, antibody, dye, e.g. Alexa488
ch1_meaning : varchar(64)   # eye injection, viral trace from brain region, transgenic line, AIS, sodium channel, etc

ch2_color : varchar(16)
ch2_label : varchar(32)
ch2_meaning : varchar(64)

ch3_color : varchar(16)
ch3_label : varchar(32)
ch3_meaning : varchar(64)

ch4_color : varchar(16)
ch4_label : varchar(32)
ch4_meaning : varchar(64)

%}

classdef ImageChannelMap < dj.Lookup
    
end