function results = SpikeDetector(D)
HighPassCut_drift = 70; %Hz, in order to remove drift and 60Hz noise
HighPassCut_spikes = 100; %Hz, in order to remove everything but spikes
SampleInterval = 1E-4;
ref_period = 2E-3; %s
searchInterval = 1E-3; %s
%make parameter for direction detection, or try both if not too slow

results = [];

%thres = 25; %stds
ref_period_points = round(ref_period./SampleInterval);
searchInterval_points = round(searchInterval./SampleInterval);

[Ntraces,L] = size(D);
D_noSpikes = BandPassFilter(D,HighPassCut_drift,HighPassCut_spikes,SampleInterval);
Dhighpass = HighPassFilter(D,HighPassCut_spikes,SampleInterval);

sp = cell(Ntraces,1);
spikeAmps = cell(Ntraces,1);
violation_ind = cell(Ntraces,1);
minSpikePeakInd = zeros(Ntraces,1);
maxNoisePeakTime = zeros(Ntraces,1);

for i=1:Ntraces
    %get the trace and noise_std
    trace = Dhighpass(i,:);
    trace(1:20) = D(i,1:20) - mean(D(i,1:20));
    %     plot(trace);
    %     pause;
    if abs(max(trace)) > abs(min(trace)) %flip it over
        trace = -trace;
    end
    
    
    trace_noise = D_noSpikes(i,:);
    noise_std = std(trace_noise);
    
    %get peaks
    [peaks,peak_times] = getPeaks(trace,-1); %-1 for negative peaks
    peak_times = peak_times(peaks<0); %only negative deflections
    peaks = trace(peak_times);
    
    %basically another filtering step:
    %remove single sample peaks, don't know if this helps
    trace_res_even = trace(2:2:end);
    trace_res_odd = trace(1:2:end);
    [null,peak_times_res_even] = getPeaks(trace_res_even,-1);
    [null,peak_times_res_odd] = getPeaks(trace_res_odd,-1);
    peak_times_res_even = peak_times_res_even*2;
    peak_times_res_odd = 2*peak_times_res_odd-1;
    peak_times = intersect(peak_times,[peak_times_res_even,peak_times_res_odd]);
    peaks = trace(peak_times);
    
    %add a check for rebounds on the other side
    r = getRebounds(peak_times,trace,searchInterval_points);
    peaks = abs(peaks);
    peakAmps = peaks+r;
    
    if ~isempty(peaks) && max(D(i,:)) > min(D(i,:)) %make sure we don't have bad/empty trace
        
        options = statset('MaxIter',10000);
        startAmps = prctile(peakAmps,[.33 .66 .99])';
        
        
        %[Ind,centroid_amps] = kmeans(peakAmps,3,'start',startAmps,'Options',options);
        [Ind,centroid_amps] = kmeans(sqrt(peakAmps),2,'start',sqrt([median(peakAmps);max(peakAmps)]),'Options',options);
        
        %other clustering approaches that I dedcided not to use
%         
%         figure(2);
%         hist(peakAmps,50);
%         [x,y] = ginput;
%         th = x(end);
% %        th = input('threshold ');
%         spike_ind_log = peakAmps>th;
        
        %obj = gmdistribution.fit(sqrt(peakAmps'),2,'Options',options);
        %         %Ind = cluster(obj,sqrt(peakAmps'));
        %         [centroid_amps_sorted, sortInd] = sort(centroid_amps);
        %         %if centroid_amps_sorted(3) - centroid_amps_sorted(2) <  1.5*(centroid_amps_sorted(2) - centroid_amps_sorted(1))
        %         %if second cluster closer to max spike cluster than noise
        %         if centroid_amps_sorted(2) > 2 * centroid_amps_sorted(3)
        %
        %             spike_ind_log = (Ind==sortInd(3) | Ind==sortInd(2));
        %         else
        %             spike_ind_log = (Ind==sortInd(3));
        %             %spike_ind_log = (Ind==sortInd(2));
        %         end
        
        [m,m_ind] = max(centroid_amps);
        spike_ind_log = (Ind==m_ind);
        
        %spike_ind_log is logical, length of peaks
        
        %keyboard;
        
        if sum(spike_ind_log)>0 %if any spikes found
            %distribution separation check
            spike_peaks = peakAmps(spike_ind_log);
            nonspike_peaks = peakAmps(~spike_ind_log);
            nonspike_Ind = find(~spike_ind_log);
            spike_Ind = find(spike_ind_log);
            [m,sigma,m_ci,sigma_ci] = normfit(sqrt(nonspike_peaks));
            mistakes = find(sqrt(nonspike_peaks)>m+5*sigma);
            
            
            %no spikes check - still not real happy with how sensitive this is
            if mean(sqrt(spike_peaks)) < mean(sqrt(nonspike_peaks)) + 4*sigma; %no spikes
                disp(['Epoch ' num2str(i) ': no spikes']);
                sp{i} = [];
                spikeAmps{i} = [];
                
            else %spikes found
                overlaps = length(find(spike_peaks < max(nonspike_peaks)));%this check will not do anything
                if overlaps > 0
                    disp(['warning: ' num2str(overlaps) ' spikes amplitudes overlapping tail of noise distribution']);
                end
                sp{i} = peak_times(spike_ind_log);
                spikeAmps{i} = peakAmps(spike_ind_log)./noise_std;
                
                [minSpikePeak,minSpikePeakInd(i)] = min(spike_peaks);
                [maxNoisePeak,maxNoisePeakInd] = max(nonspike_peaks);
                maxNoisePeakTime(i) = peak_times(nonspike_Ind(maxNoisePeakInd));
                
                %check for violations again, just for warning this time
                violation_ind{i} = find(diff(sp{i})<ref_period_points) + 1;
                ref_violations = length(violation_ind{i});
                if ref_violations>0
                    %find(diff(sp{i})<ref_period_points)
                    disp(['warning, trial '  num2str(i) ': ' num2str(ref_violations) ' refractory violations']);
                end
            end %if spikes found
        end
    end %end if not bad trace
end

if length(sp) == 1 %return vector not cell array if only 1 trial
    sp = sp{1};
    spikeAmps = spikeAmps{1};
    violation_ind = violation_ind{1};
end

results.sp = sp;
results.spikeAmps = spikeAmps;
results.minSpikePeakInd = minSpikePeakInd;
results.maxNoisePeakTime = maxNoisePeakTime;
results.violation_ind = violation_ind;
