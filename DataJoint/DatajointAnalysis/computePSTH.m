function [psth_x, psth_y, baseline] = computePSTH(cellData_name, ch, pre_time, stim_time, post_time, epoch_ids, psth_params_name)
% input times in ms
% ch is which amp channel (1 or 2)
% needs spike trains already computed for these epochs as SpikeTrain objects
% needs PSTHParams set with psth_params_id defined

%get psth calculation parameters
q.param_set_name = psth_params_name;
psth_params = sl_test.PSTHParamSet & q;
if psth_params.count ~= 1
    disp(['Error in computePSTH: could not load PSTHParams with name ' psth_params_name]);
    return;
end
psth_bin = fetch1(psth_params, 'psth_bin');
gauss_win = fetch1(psth_params, 'gauss_win');
sliding_win = fetch1(psth_params, 'sliding_win');
baseline_subtract = fetch1(psth_params, 'baseline_subtract');

%compute PSTH
N_epochs = length(epoch_ids);
N_samples = ceil((pre_time + stim_time + post_time) / psth_bin);
total_time_ms = pre_time + stim_time + post_time; %ms

psth_x = [0:N_samples-1] * psth_bin / 1E3 - pre_time / 1E3; % units of seconds

allSpikes = [];
q = struct;
q.cell_data = cellData_name;
for i=1:N_epochs
    q.number = epoch_ids(i);
    if ch==1
        q.channel = 1;
    elseif ch==2
        q.channel = 2;
    else
        disp(['SMSSpikeData failed to get spikes_ch ' num2str(ch)]);
        return;
    end
    sp_train = sl_test.SpikeTrain & q;
    ep = sl_test.Epoch & q;
    sample_rate = fetch1(ep,'sample_rate');    
    N_trains = sp_train.count;
    if N_trains == 0
        disp(['SMSSpikeData failed to get spikes: ' q.cell_data ': epoch ' num2str(q.number)]);
        return;
    elseif N_trains > 1
        disp(['SMSSpikeData duplicate spike train: ' q.cell_data ': epoch ' num2str(q.number)]);
        return;
    else
        cur_sp = fetch1(sp_train, 'sp');
        if ischar(cur_sp) %not a real spike train
            disp(['SMSSpikeData: ' q.cell_data ': epoch ' num2str(q.number) 'spikeTrain = ' cur_sp]);
        else
            cur_sp = 1E3 * cur_sp ./ sample_rate; %now in units of ms, starting at zero
            allSpikes = [allSpikes cur_sp];
        end
    end
end

disp([num2str(length(allSpikes)) ' spikes found']); 

bins = 0:psth_bin:total_time_ms;

spCount = histcounts(allSpikes,bins);
if gauss_win > 0
    w = gausswin(gauss_win);
    w = w / sum(w); %normalize correctly
    spCount = conv(spCount,w,'same');
elseif sliding_win > 0
    spCount = smooth(spCount,sliding_win);
end

if isempty(spCount)
   spCount = zeros(1,length(bins));
end

%convert to Hz
psth_y = 1E3 * spCount ./ (N_epochs * psth_bin);

if baseline_subtract
   baseline = mean(psth_y(psth_x < 0));
   psth_y = psth_y - baseline;
end



