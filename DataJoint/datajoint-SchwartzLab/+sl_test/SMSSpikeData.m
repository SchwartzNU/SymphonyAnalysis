%{
# SMSSpikeData
-> sl.DatasetSMS
-> sl.PSTHParamSet
---
pre_time : int unsigned           # length of time before stimulus (ms)
stim_time : int unsigned          # length of stimulus (ms)
post_time : int unsigned          # length of time after stimulus (ms)
psth_x : longblob                 # x values of PSTH in seconds, 0 is stimulus onset
spot_sizes : longblob             # vector of spot sizes in microns
sms_psth : longblob               # array with PSTH for a different spot size in each row
sms_spike_count_onset_mean : longblob  # spike count mean for each spot size at stimulus onset
sms_spike_count_offset_mean : longblob # spike count mean for each spot size at stimulus offset
sms_spike_count_onset_sem : longblob   # spike count sem for each spot size at stimulus onset
sms_spike_count_offset_sem : longblob  # spike count sem for each spot size at stimulus offset
%}

classdef SMSSpikeData < dj.Computed
    methods(Access=protected)
        function makeTuples(self,key)
            dataset_name = key.dataset_name;
            dataset = sl.Dataset & key;
            if strcmp(fetch1(dataset,'recording_type'), 'Cell attached') %only for CA SMS datasets
                cellData_name = key.cell_data;
                disp(['Computing SMS Spike Data for ' cellData_name ':' dataset_name]);
                cellData = loadAndSyncCellData(cellData_name);
                epoch_ids = fetch1(dataset, 'epoch_ids');
                [passed, paramStruct] = self.dataCheck(cellData, epoch_ids);
                
                if passed
                    ch = fetch1(dataset, 'channel');
                    
                    %Note could generalize this and refactor
                    spot_size_vector = round(cellData.getEpochVals('curSpotSize', epoch_ids));
                    spot_sizes = sort(unique(spot_size_vector), 'ascend');
                    paramStruct.spot_sizes = spot_sizes;
                    N_spot_sizes = length(paramStruct.spot_sizes);
                    
                    sms_spike_count_onset_mean = zeros(1,N_spot_sizes);
                    sms_spike_count_onset_sem = zeros(1,N_spot_sizes);
                    sms_spike_count_offset_mean = zeros(1,N_spot_sizes);
                    sms_spike_count_offset_sem = zeros(1,N_spot_sizes);
                    
                    for ss=1:N_spot_sizes
                        curSize = paramStruct.spot_sizes(ss);
                        ind = spot_size_vector == curSize;
                        cur_epoch_ids = epoch_ids(ind);
                        
                        [psth_x, psth_y] = computePSTH(cellData_name, ch, ...
                            paramStruct.pre_time, paramStruct.stim_time, paramStruct.post_time, ...
                            cur_epoch_ids, key.param_set_name);
                        
                        N_epochs = length(cur_epoch_ids);     
                        
                        q = struct;
                        q.cell_data = cellData_name;  
                        q.channel = ch;
                        spCount_ON = zeros(1,N_epochs);
                        spCount_OFF = zeros(1,N_epochs);
                        for e=1:N_epochs
                            q.number = cur_epoch_ids(e);
                            cur_train = sl.SpikeTrain & q;
                            
                            spCount_ON(e) = spikesInInterval(cur_train, 0.04, 1.04, 'preTime');
                            spCount_OFF(e) = spikesInInterval(cur_train, 1.04, 2.04, 'preTime');
                        end
                        sms_spike_count_onset_mean(ss) = mean(spCount_ON);
                        sms_spike_count_onset_sem(ss) = std(spCount_ON)./sqrt(N_epochs-1);
                        sms_spike_count_offset_mean(ss) = mean(spCount_OFF);
                        sms_spike_count_offset_sem(ss) = std(spCount_OFF)./sqrt(N_epochs-1);
                        
                        if ss==1 %initialize
                            sms_psth = zeros(N_spot_sizes, length(psth_x));
                        end
                        sms_psth(ss,:) = psth_y;
                    end
                    
                    key.pre_time = paramStruct.pre_time;
                    key.stim_time = paramStruct.stim_time;
                    key.post_time = paramStruct.post_time;
                    key.psth_x = psth_x;
                    key.spot_sizes = paramStruct.spot_sizes;
                    key.sms_psth = sms_psth;
                    key.sms_spike_count_onset_mean = sms_spike_count_onset_mean;
                    key.sms_spike_count_onset_sem = sms_spike_count_onset_sem;
                    key.sms_spike_count_offset_mean = sms_spike_count_offset_mean;
                    key.sms_spike_count_offset_sem = sms_spike_count_offset_sem;
                    self.insert(key);
                else
                    disp([cellData_name ':' dataset_name ' failed SMS data check']);
                    return
                end
            end
        end
    end
    
    methods
        function [passed, paramStruct] = dataCheck(self, cellData, epoch_ids)
            passed = false;
            if isempty(epoch_ids), return; end
            paramStruct = struct;
            ep1 = cellData.epochs(epoch_ids(1));
            
            all_pre_time = cellData.getEpochVals('preTime', epoch_ids);
            all_stim_time = cellData.getEpochVals('stimTime', epoch_ids);
            all_post_time = cellData.getEpochVals('tailTime', epoch_ids);
            if length(unique(all_pre_time)) > 1 || ...
                    length(unique(all_stim_time)) > 1 || ...
                    length(unique(all_post_time)) > 1 % only one set of pre/stim/post time
                return;
            end
            if ep1.get('stimTime') ~= 1000 %need 1s stim_time for this, maybe? M1?
                return;
            end
                   
            paramStruct.pre_time = ep1.get('preTime');
            paramStruct.stim_time = ep1.get('stimTime');
            paramStruct.post_time = ep1.get('tailTime');
            
            passed = true;
        end
    end
end