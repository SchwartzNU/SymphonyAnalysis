%{
# SpotsMultiSize Dataset
-> sl_test.Dataset
---
mean_luminance              : float                         # R*/rod/s
spot_luminance              : float                         # R*/rod/s
sms_one_per_cell_exclude="false": enum('true','false')      # false or true
%}

classdef DatasetSMS < dj.Part
    properties(SetAccess=protected)
        master = sl_test.Dataset
    end
    methods(Static)
        function makeTuples(self, key)
            epoch_ids = fetch1(sl_test.Dataset & key, 'epoch_ids');
            %dataset_name = fetch1(sl_test.Dataset & key, 'epoch_ids');            
            cellData = loadAndSyncCellData(key.cell_data);
            
            mean_luminance_unique = unique(cellData.getEpochVals('RstarMean', epoch_ids));
            spot_luminance_unique = unique(cellData.getEpochVals('RstarIntensity', epoch_ids));
            
            if length(mean_luminance_unique) > 1
                disp(['Error creating DatasetSMS for cell ' key.dataset_name ': multiple mean luminance values']);
                return;
            end
            if isnan(spot_luminance_unique(1)) %try other parameter name
                spot_luminance_unique = unique(cellData.getEpochVals('RstarIntensity1', epoch_ids));
            end
            
            if length(spot_luminance_unique) > 1
                disp(['Error creating DatasetSMS for cell ' key.dataset_name ': multiple spot luminance values']);
                return;
            end
            
            ep1 = cellData.epochs(epoch_ids(1));
            sms_exclude = ep1.get('SMS_classification_remove');
            if ~isnan(sms_exclude)
                if sms_exclude
                    key.sms_one_per_cell_exclude = 'true';
                end
            end
            
            key.mean_luminance = mean_luminance_unique;
            key.spot_luminance = spot_luminance_unique;
            
            self.insert(key);
        end
    end
end
