%{
# Dataset
-> sl.RecordedNeuron
cell_data                   : varchar(128)                  # name of cellData file
dataset_name                : varchar(128)                  # name of dataset
channel=1                   : int unsigned                  # amplifier channel
---
recording_type              : enum('Cell attached','Whole cell','Multi','U') # 
epoch_ids                   : longblob                      # set of epochs in this dataset
%}

classdef Dataset < dj.Manual
   
end
