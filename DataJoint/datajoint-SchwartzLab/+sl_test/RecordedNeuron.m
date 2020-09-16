%{
# RecordedNeuron
-> sl_test.Neuron

---
position_x : float              # x position in the retina, optic nerve at 0,0
position_y : float              # y position in the retina, blank for unknown
which_eye : enum('R', 'L', 'U') # Right, Left, or unknown
number_of_epochs : int unsigned # total number of recorded epochs
cell_type : varchar(64)         # type of cell
experimenter : varchar(64)      # who recorded it
online_label : varchar(128)     # text in cellType field in symphony during recording
notes = NULL : varchar(1000)    # unstructured text for notes
tags : longblob                 # struct with tags
%}

classdef RecordedNeuron < dj.Imported
    properties
        excluded_epoch_params = {'spikes_ch1', ...
            'spikes_ch2', ...
            'spikeThreshold', ...
            'spikeDetection', ...
            'responseType', ...
            'maxPatternsPerFrame', ...
            'lowPassFreq', ...
            'epochNum', ...
            'sampleRate', ...
            'amplifierMode', ...
            'ampMode', ...
            'amp'};
    end
    
    methods(Access=protected)
        function makeTuples(self,key)
            cellNames = strtrim(split(key.cell_id,','));
            N_cellData = length(cellNames);
            for n=1:N_cellData
                [curName, ch] = strtok(cellNames{n}, '-');
                channel = 1;
                if ~isempty(ch)
                    channel = str2double(ch(4));
                end
%                 key.cell_data_list{n} = curName;
%                 key.channel_list(n) = channel;
                
                cellData = loadAndSyncCellData(curName);
%                 key.dataset_list{n} = cellData.savedDataSets;
                
                if isKey(cellData.attributes, 'symphonyVersion') %if has this key at all, it has fname
                    raw_data_filename = cellData.get('fname');
                else
                    raw_data_filename = curName;
                end
                
                loc = cellData.location;
                if length(loc) == 3 %has all 3 coordinates
                    if (loc(1) ~= 0 || loc(2) ~= 0) && ~isnan(loc(1)) && ~isnan(loc(2)) %at least one nonzero
                        key.position_x = loc(1);
                        key.position_y = loc(2);
                        if loc(3) < 0
                            key.which_eye = 'L';
                        else
                            key.which_eye = 'R';
                        end
                    else
                        key.position_x = 0;
                        key.position_y = 0;
                    end
                else
                    key.which_eye = 'U';
                    key.position_x = 0;
                    key.position_y = 0;
                end
                key.online_label = '';
                if find(strcmp(cellData.attributes.keys, 'type'))
                    if ~isempty(cellData.attributes('type'))
                        key.online_label = cellData.attributes('type');
                    end
                elseif find(strcmp(cellData.attributes.keys, 'label'))
                    if ~isempty( cellData.attributes('label'))
                        key.online_label = cellData.attributes('label');
                    end
                end
                if ~ischar(key.online_label)
                    key.online_label = '';
                end
                key.number_of_epochs = cellData.attributes('Nepochs');
                key.cell_type = cellData.cellType;
                
                tagsMap = cellData.tags;
                k = tagsMap.keys;
                s = struct;
                key.experimenter = '';
                for i=1:length(k)
                    if strcmp(k{i}, 'RecordedBy')
                        key.experimenter = tagsMap('RecordedBy');
                    else
                        s.k{i} = tagsMap(k{i});
                    end
                end
                key.tags = s;
                
                if n==1 %only insert self key once, data pulled from first listed cell
                    % insert the key into self
                    self.insert(key)
                end
                
                %add all epochs
                for e=1:key.number_of_epochs
                    %disp(['trying add epoch ' num2str(e)]);                    
                    epoch_insert_error = false;
                    epoch_init_struct = struct;
                    epoch_init_struct.cell_id = key.cell_id;
                    epoch_init_struct.number = e;
                    epoch_init_struct.cell_data = curName;
                    epoch_init_struct.protocol_params = struct;
                    epoch_init_struct.raw_data_filename = raw_data_filename;
                    %load required epoch values
                    ep = cellData.epochs(e);
                    
                    %required params. Error if we don't find these
                    epoch_init_struct.sample_rate = ep.get('sampleRate');
                    epoch_init_struct.epoch_start_time = ep.get('epochStartTime');
                    
                    mode = ep.get('ampMode');
                    if isnan(mode), mode = 'U'; end
                    epoch_init_struct.recording_mode = mode;
                    
                    mode2 = ep.get('amp2Mode');
                    if isnan(mode2), mode2 = 'Off'; end
                    epoch_init_struct.recording2_mode = mode2;
                    
                    ampmode = ep.get('amplifierMode');
                    if isnan(ampmode), ampmode = 'U'; end
                    epoch_init_struct.amp_mode = ampmode;
                    
                    amp2mode = ep.get('amplifier2Mode');
                    if isnan(amp2mode), amp2mode = 'U'; end
                    epoch_init_struct.amp2_mode = amp2mode;
                    
                    %data links
                    try
                        dlMap = ep.dataLinks;
                        epoch_init_struct.data_link = dlMap('Amplifier_Ch1');
                        if dlMap.isKey('Amplifier_Ch2')
                            epoch_init_struct.data_link2 = dlMap('Amplifier_Ch2');
                        end
                    catch
                        disp(['DataLink not found for ' epoch_init_struct.cell_data ' epoch: ' num2str(e)]);
                        disp('Epoch not added');
                        epoch_insert_error = true;
                    end
                    
                    %insert epoch only if it's not already there
                    qstruct.cell_id = epoch_init_struct.cell_id;
                    qstruct.number = epoch_init_struct.number;
                    qstruct.cell_data = epoch_init_struct.cell_data;
                    q = sl_test.Epoch & qstruct;
                    if q.count == 0 % epoch not already inserted
                        %load protocol params
                        epMap = ep.attributes;
                        epMap_keys = epMap.keys;
                        paramStruct = struct;
                        for j=1:length(epMap_keys)
                            if ~ismember(epMap_keys{j}, self.excluded_epoch_params)
                                field_name = epMap_keys{j};
                                field_name = strrep(field_name, '.', '_dot_'); %make sure field name is legal
                                paramStruct.(field_name) = epMap(epMap_keys{j});
                            end
                        end
                        epoch_init_struct.protocol_params = paramStruct;
                        if ~epoch_insert_error
                            insert(sl_test.Epoch, epoch_init_struct, 'REPLACE');
                        end
                    end
                end
                
               %add all datasets
               datasetNames = cellData.savedDataSets.keys;
               N_datasets = length(datasetNames);
               for d=1:N_datasets
                   s = struct;
                   s.cell_id = key.cell_id;
                   s.cell_data = curName;
                   s.channel = channel;
                   s.dataset_name = datasetNames{d};
                   s.dataset_name = strrep(s.dataset_name, '.', '_dot_'); %make sure dataset_name is legal
                   disp(['Adding dataset: '  s.dataset_name]);
                   sl_test.Dataset.makeTuples(sl_test.Dataset, s);
               end
    
            end
            
        end
    end
end



%-> sl.image
%data sets

% cell_data_list : longblob       # cell array of cellData names
% channel_list : longblob         # vector of channel numbers, same size as cell_data_list
% dataset_list : longblob         # cell array of data_set maps