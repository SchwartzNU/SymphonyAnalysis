%{
# SpikeTrain, can have 2 per epoch if there are 2 channels
-> sl.Epoch
channel = 1 : int unsigned  # amplifier channel
---
sp : longblob               # the spike train (vector), or 'not computed', or 'NA'
%}

classdef SpikeTrain < dj.Imported
    methods(Access=protected)
        function makeTuples(self, key)
            q = sl.SpikeTrain & key;
            if q.count > 0
                previous_ch = fetch1(q, 'channel');
                if previous_ch == 1
                    ch = 2; 
                    key.channel = 2;
                else
                    ch = 1; 
                    key.channel = 1;
                end
            else
                ch = 1;
            end
            
            ep = sl.Epoch & key;
            if ch==1
                mode = fetch1(ep,'recording_mode');
            elseif ch==2
                mode = fetch1(ep,'recording2_mode');
            else
                disp(['SpikeTrain: invalid channel ' num2str(ch)]);
            end
            if strcmp(mode, 'Cell attached')
                cellData = loadAndSyncCellData(key.cell_data);
                epData = cellData.epochs(key.number);
                if ch==1
                    key.sp = epData.get('spikes_ch1');
                elseif ch==2
                    key.sp = epData.get('spikes_ch2');
                end
            else
                key.sp = 'NA';
            end
            self.insert(key);
        end
    end
end
