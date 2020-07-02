function [SMS_struct, sms_psth_mean, N_cells, ON_mean, ON_std, OFF_mean, OFF_std] = extract_meanSMSDataForRGCType(cell_type_name, fname)
queryResult = sl.RecordedNeuron * sl.SMSSpikeData & ['cell_type =  "' cell_type_name '"'];
SMS_struct = fetch(queryResult, 'sms_spike_count_onset_mean', 'sms_spike_count_offset_mean', 'spot_sizes', 'sms_psth', 'psth_x');

size_min = 1;
size_max = 1200;
size_bins = 50;

N_cells = length(SMS_struct);

data = {SMS_struct.sms_psth}'; %a cell array of PSTHs
timeVec = {SMS_struct.psth_x}';
sizeVec = {SMS_struct.spot_sizes}'; %a cell array of spot sizes matching the PSTHs
sizeBins = logspace(size_min,log10(size_max), size_bins); %an example list of desired spot sizes;
timeRange = [-1 2];

dt = .01; %time bin (s)
%sizeBins and timeRange are not quite in right format
[sizeInd,tind] = meshgrid(sizeBins,timeRange(1):dt:timeRange(2));
%timeVec must be in the form of a list of start and end times
tMin = cellfun(@min,timeVec);
tMax = cellfun(@max,timeVec);
timeVec = [tMin tMax];
%need to make sure index vectors are in correct orientation, see help rebinData for guidance
data_rebinned = rebinData(data,sizeVec,(sizeInd(:))',timeVec,tind(:),dt);
data_rebinned = reshape(data_rebinned,[numel(data) size(sizeInd)]);
sms_psth_mean = squeeze(mean(data_rebinned,1))';

ON_matrix = zeros(N_cells, size_bins);
OFF_matrix = zeros(N_cells, size_bins);

ON_max = zeros(1,N_cells);
OFF_max = zeros(1,N_cells);

for i=1:N_cells
    ON_max(i) = max(SMS_struct(i).sms_spike_count_onset_mean);
    OFF_max(i) = max(SMS_struct(i).sms_spike_count_offset_mean);
    ON_matrix(i,:) = interp1(SMS_struct(i).spot_sizes, SMS_struct(i).sms_spike_count_onset_mean, sizeBins, 'nearest', 'extrap');
    OFF_matrix(i,:) = interp1(SMS_struct(i).spot_sizes, SMS_struct(i).sms_spike_count_offset_mean, sizeBins, 'nearest', 'extrap');
end

maxSpikes = max([ON_max OFF_max]);

ON_mean = nanmean(ON_matrix,1);
ON_std = nanstd(ON_matrix,[],1);
OFF_mean = nanmean(OFF_matrix,1);
OFF_std = nanstd(OFF_matrix,[],1);

timeAxis = timeRange(1):dt:timeRange(2);

if nargin == 2
   save(fname, 'SMS_struct', 'N_cells', 'cell_type_name', 'sms_psth_mean', ...
   'timeRange', 'timeAxis', 'dt', 'sizeBins', 'maxSpikes', ...
   'ON_mean', 'ON_std', ...
   'OFF_mean', 'OFF_std');
end


