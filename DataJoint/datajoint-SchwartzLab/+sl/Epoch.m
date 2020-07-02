%{
# Epoch
-> sl.RecordedNeuron
number                      : int unsigned                  # epoch number
cell_data                   : varchar(128)                  # name of cellData file
---
sample_rate                 : int unsigned                  # samples per second
epoch_start_time            : float                         # seconds since start of cell
recording_mode              : enum('Cell attached','Whole cell','U','Off') # recording mode U = unknown
recording2_mode             : enum('Cell attached','Whole cell','U','Off') # recording mode U = unknown
amp_mode                    : enum('Vclamp','Iclamp','U')   # amplifier mode, U = unknown
amp2_mode                   : enum('Vclamp','Iclamp','U')   # amplifier mode, U = unknown
protocol_params             : longblob                      # struct of protocol parameters
raw_data_filename           : varchar(32)                   # raw data filename without .h5 extension
data_link                   : varchar(512)                  # hdf5 location of raw data - channel 1
data_link2=NULL             : varchar(512)                  # hdf5 location of raw data - channel 2
%}

classdef Epoch < dj.Manual   
    methods

        function [data, xvals, units] = getData(self, channel)
            global RAW_DATA_FOLDER;
            if nargin < 2
                channel = 1;
            end
            
            data = [];
            xvals = [];
            units = '';
            
            if channel == 1
                dL = fetch1(self,'data_link');
            elseif channel == 2
                dL = fetch1(self,'data_link2');
            else
                disp(['Epoch getData: invalid channel ' num2str(channel)]);
                return;
            end
            
            if isempty(dL)
                disp(['Epoch getData: datalink is empty for channel ' num2str(channel)]);
                return;
            end
            
            fname = fetch1(self,'raw_data_filename');
            
            temp = h5read(fullfile(RAW_DATA_FOLDER, [fname '.h5']), dL);
            data = temp.quantity;
            if isfield(temp,'units')
                units = deblank(temp.units(:,1)');
            else
                units = deblank(temp.unit(:,1)');
            end
            
            sampleRate = fetch1(self,'sample_rate');
            %%temp hack for old data?
            %if ischar(obj.get('preTime'))
            %    obj.attributes('preTime') = str2double(obj.get('preTime'));
            %end        
            params = fetch1(self,'protocol_params');
            stimStart = params.preTime * 1E-3; %s
            if ~isfield(params,'stimStart')
                stimStart = 0;
            end
            xvals = (1:length(data)) / sampleRate - stimStart;
        end
        
    end
end

%raw_data_link : varchar(256)  # check this... hdf5 path

