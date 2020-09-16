%{
# Dataset
-> sl_test.RecordedNeuron
cell_data                   : varchar(128)                  # name of cellData file
dataset_name                : varchar(128)                  # name of dataset
channel=1                   : int unsigned                  # amplifier channel
---
recording_type=NULL         : enum('Cell attached','Whole cell','Multi','U') #
epoch_ids=NULL              : longblob                      # set of epochs in this dataset
%}

classdef Dataset < dj.Manual
    methods(Static)
        function makeTuples(self,key)
            cellData = loadAndSyncCellData(key.cell_data);
            datasetsMap = cellData.savedDataSets;
            key.epoch_ids = datasetsMap(key.dataset_name);
            
            N_epochs = length(key.epoch_ids);
            allModes = cell(1,N_epochs);
            if key.channel==1
                mode_param = 'recording_mode';
            elseif key.channel==2
                mode_param = 'recording2_mode';
            else
                disp(['Error: in Dataset initialization, channel ' num2str(key.channel) ' not found']);
                return;
            end
            
            for e=1:N_epochs
                q.cell_id = key.cell_id;
                q.number = key.epoch_ids(e);                
                allModes{e} = fetch1(sl_test.Epoch & q, mode_param);
            end
            
            unique_modes = unique(allModes);
            
            if length(unique_modes) == 1
                key.recording_type = unique_modes{1};
            else
                key.recording_type = 'Multi';
            end
            
            self.insert(key)
            
            %remove fields only in DataSet
            partKey = rmfield(key, {'recording_type', 'epoch_ids'});
            
            %now the specific calls for each kind of dataset
            if startsWith(key.dataset_name, 'SpotsMultiSize') %only for SMS datasets
                sl_test.DatasetSMS.makeTuples(sl_test.DatasetSMS, partKey);
            end
            
        end
    end
end

