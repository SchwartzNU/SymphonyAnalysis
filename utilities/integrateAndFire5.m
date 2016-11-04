% Integrate and fire

%DEFINE PARAMETERS
dt = 0.1; %time step [ms]
t_start = -500;
t_end = 2000; %total time of run [ms]
t_StimStart = 0; %time to start injecting current [ms]
t_StimEnd = 1000; %time to end injecting current [ms]
E_L = -60; %resting membrane potential [mV]
V_th = -48; %spike threshold [mV] -20
V_reset = -70; %value to reset voltage to after a spike [mV]
V_spike = 20; %value to draw a spike to, when cell spikes [mV]
R_m = 500; %membrane resistance [MOhm]
tau_mem = 1; %membrane time constant [ms]
tau_refractory = 20; %refractory period membrane time constant [ms]
factor_refractory = 2; %multiple of tau_refractory until tau changes back, after a spike (~2 to 4) 
tau = tau_mem;
Vr_exc = 20; %[mV]
Vr_inh = -60; %[mV]


countWindowStart = 0; %[ms]
countWindowEnd = 1500; %[ms]


%get data
%generate data using:
%"nodesData = getTracesFromTree(analysisTree,'SpotsMultiSizeAnalysis')"

% % %103015Ac10
% nodesData = nodesData_103015Ac10;
% datasetNum_CA = 1;
% datasetNum_exc = 2;
% datasetNum_inh = 5;

%100215Bc1
nodesData = nodesData_100215Bc1;
datasetNum_CA = 1;
datasetNum_exc = 2;
datasetNum_inh = 3;


% % %101615Ac5
% nodesData = nodesData_101615Ac5;
% datasetNum_CA = 1;
% datasetNum_exc = 3;
% datasetNum_inh = 4;

% %110415Ac2
% nodesData = nodesData_110415Ac2;
% datasetNum_CA = 3; %no CA dataset!!!
% datasetNum_exc = 1;
% datasetNum_inh = 2;

% %102715Bc14
% nodesData = nodesData_102715Bc14;
% datasetNum_CA = 8;
% datasetNum_exc = 1;
% datasetNum_inh = 7;

% %102215Ac2
% nodesData = nodesData_102215Ac2;
% datasetNum_CA = 1;
% datasetNum_exc = 2;
% datasetNum_inh = 6;

splitParam = [nodesData(datasetNum_CA).childData.splitValue]';
N_splitParam = length(splitParam);
%N_splitParam = 10;

%structtures to store results
spikeCountMean_vecBySplitParam = zeros(N_splitParam, 1);
spikeCountStd_vecBySplitParam = zeros(N_splitParam, 1);
hmsLatency_vecBySplitParam = zeros(N_splitParam, 1);


for sp = 1:N_splitParam
    dataMatrixExc = nodesData(datasetNum_exc).childData(sp).rawDataMatrix;
    dataMatrixInh = nodesData(datasetNum_inh).childData(sp).rawDataMatrix;
    %Conductance data
    %mV/MOhm = nA => need currents in nA not pA.
    %*1e-3 = conversion pA to nA
    %I = g(V-Vr) was taken in voltage clamp +20mV, -60mV, hence 1/(-80mV)
    g_dataMatrixExc = dataMatrixExc.*1e-3/(-80); %[micro-Siemens]
    g_dataMatrixInh = dataMatrixInh.*1e-3/80;
    %     g_meanDataExc = meanDataExc.*1e-3/(-80);
    %     g_meanDataInh = meanDataInh.*1e-3/80;
    
    
    
    
    t_vect = t_start:dt:t_end; %will hold vector of times
    
    
    N_epochs_exc = length(dataMatrixExc(:,1));
    N_epochs_inh = length(dataMatrixInh(:,1));
    N_epochs = N_epochs_exc * N_epochs_inh; %simulate epochs from all combinations of exc/inh epochs that I have
    
    %Baseline subtraction
    for epoch = 1:N_epochs_exc
        bl = mean(g_dataMatrixExc(epoch, t_vect<t_StimStart));
        g_dataMatrixExc(epoch,:) = g_dataMatrixExc(epoch,:) - bl;
    end;
    for epoch = 1:N_epochs_inh
        bl = mean(g_dataMatrixInh(epoch, t_vect<t_StimStart));
        g_dataMatrixInh(epoch,:) = g_dataMatrixInh(epoch,:) - bl;
    end;
    %     bl = mean(g_meanDataExc(t_vect<t_StimStart));
    %     g_meanDataExc = g_meanDataExc - bl;
    %     bl = mean(g_meanDataInh(t_vect<t_StimStart));
    %     g_meanDataInh = g_meanDataInh - bl;
    
    
    
    spikeTimes = [];
    %N_epochs = 1;
    refractoryTimer = 0;
    
    epochSpikes = []; 
    
    for epExc = 1:N_epochs_exc %nested loop over epochs
        for epInh = 1:N_epochs_inh
            curEpochSpikes = 0;
            
            g_exc = g_dataMatrixExc(epExc,:);
            g_inh = g_dataMatrixInh(epInh,:);
            V_vect = zeros(1,length(t_vect)); %initialize the voltage vector
            %initializing vectors makes your code run faster!
            V_plot_vect = zeros(1,length(t_vect)); %pretty version of V_vect to be plotted, that displays a spike
            % whenever voltage reaches threshold
            %INTEGRATE THE EQUATION tau*dV/dt = -V + E_L + I_e*R_m
            
            V_vect(1)= E_L; %first element of V, i.e. value of V at t=0
            V_plot_vect(1) = V_vect(1); %if no spike, then just plot the actual voltage V
            
            I_e_vect = zeros(1, t_end-t_start/dt);
            
            
            for i = 1:length(t_vect)-1 %loop through values of t in steps of dt ms
                I_e_vect(i) = (V_vect(i) - Vr_exc)*g_exc(i) + (V_vect(i) - Vr_inh)*g_inh(i);
                %         V_inf = E_L + I_e_vect(i)*R_m; %value that V_vect is exponentially
                %         %decaying towards at this time step
                %         %next line does the integration update rule
                %        V_vect(i+1) = V_inf + (V_vect(i) - V_inf)*exp(-dt/tau); NO NEED!
                V_vect(i+1) = V_vect(i) + (dt/tau)*(E_L - V_vect(i) - I_e_vect(i)*R_m); %minus on I_e_vect(i), for inward current >0
                %if statement below says what to do if voltage crosses threshold
                if (V_vect(i+1) > V_th) %cell spiked
                    %Change tau and start refractory timer
                    tau = tau_refractory;
                    refractoryTimer = tau_refractory*factor_refractory;
                    % % %
                    V_vect(i+1) = V_reset; %set voltage back to V_reset
                    V_plot_vect(i+1) = V_spike; %set vector that will be plotted to show a spike here
                    spikeTimes = [spikeTimes,t_vect(i+1)];
                    
                    if (t_vect(i+1) >= countWindowStart)&&(t_vect(i+1) <= countWindowEnd) %count spike if inside temporal counting window
                        curEpochSpikes = curEpochSpikes+1;
                    end;
                else %voltage didn't cross threshold so cell does not spike
                    if refractoryTimer > 0 % step refractory timer if active
                        refractoryTimer = refractoryTimer-dt;
                    else
                        tau = tau_mem;
                    end;
                    V_plot_vect(i+1) = V_vect(i+1); %plot the actual voltage
                end
            end
           
            
            % % % % % PLOT MEM. POTENTIAL AND CONDUCTANCES
%             if (sp == 4) && (epExc == 1)
%                 figure;
%                 plot(t_vect.*1e-3, V_plot_vect);
%                 %plot(t_vect, V_vect);
%                 hold on;
%                 plot(t_vect([1 end]).*1e-3,[V_th V_th]);
%                 hold off;
%                 ylim([-80,40]);
%                 xlabel('Time (s)');
%                 ylabel('Voltage (mV)');
%                 title(['spot size',num2str(splitParam(sp))]);
%                 figure;
%                 plot(t_vect(1:end-1).*1e-3,g_exc.*1e3); %[s],[nS]
%                 hold on;
%                 plot(t_vect(1:end-1).*1e-3,g_inh.*1e3,'r'); %[s],[nS]
%                 xlabel('Time (s)');
%                 ylabel('Conductance (nS)');
%                 title(['spot size',num2str(splitParam(sp))]);
%             end;
%             % % % % %
            epochSpikes = [epochSpikes,curEpochSpikes]; 
        end
    end %end nested loop over epochs
    aveSpikes_overEpochsCheck = mean(epochSpikes);
    steSpikes_overEpochs = std(epochSpikes)/sqrt(N_epochs);
    
    %store spiking data
    spikeCountMean_vecBySplitParam(sp) = aveSpikes_overEpochsCheck;
    spikeCountStd_vecBySplitParam(sp) = steSpikes_overEpochs;
    
    %PSTH
    bnSz = 20; %[ms]
    timeAxis_PSTH = (t_start:bnSz:t_end-bnSz);
    PSTH = hist(spikeTimes,timeAxis_PSTH+round(bnSz/2))./bnSz.*1000./N_epochs;
%     % % % PLOT PSTHs
%     if sp >= 1 && sp<=12
%         figure(sp+N_splitParam);
%         plot(timeAxis_PSTH./1000,PSTH);
%         xlabel('Time (ms)');
%         ylabel('Spike rate (Hz)');
%         title(['spot size',num2str(splitParam(sp))]);
%     end;
%     % % % % % % % %
    
    % % % calculate half max sus. latency
    %FRthres = max(PSTH)/2;
    %FRhalfMaxSusLatency = min(timeAxis_PSTH(getSustainedThresCross(PSTH, FRthres))) * 1e-3; %[s]
    FRhalfMaxSusLatency = min(timeAxis_PSTH(getSustainedThresCross(PSTH))) * 1e-3; %[s]
    % % store latency data
    hmsLatency_vecBySplitParam(sp) = FRhalfMaxSusLatency;  

    
end

% % % PLOT GRAPHS of parameters vs. splitParamc
%splitParam = [nodesData(datasetNum_CA).childData.splitValue]';
y_sim = spikeCountMean_vecBySplitParam;
y_exper = nodesData(datasetNum_CA).spikeCount_stimInterval;
% % % % normalize spikes
y_sim = y_sim./max(y_sim);
y_exper = y_exper./max(y_exper);
% % % % % %
figure
%errorbar(splitParam, spikeCountMean_vecBySplitParam,spikeCountStd_vecBySplitParam);
plot(splitParam,y_sim);
hold on;
% plot(splitParam,y_exper,'r');
% hold off;
% % % Latency
% y_sim = hmsLatency_vecBySplitParam;
% y_exper = nodesData(datasetNum_CA).ONSET_FRhalfMaxSusLatency;
% figure
% plot(splitParam, y_sim);
% hold on;
% plot(splitParam, y_exper, 'r');
% hold off;

