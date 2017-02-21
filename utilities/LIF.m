
% Integrate and fire

%DEFINE PARAMETERS
dt = 0.1; %time step [ms]
t_start = -500;
t_end = 2000; %total time of run [ms]
t_StimStart = 0; %time to start injecting current [ms]
t_StimEnd = 1000; %time to end injecting current [ms]
E_L = -62; %resting membrane potential [mV]
V_th = -56; %spike threshold [mV]
V_reset = -70; %value to reset voltage to after a spike [mV]
V_spike = 20; %value to draw a spike to, when cell spikes [mV]
R_m = 500; %membrane resistance [MOhm]
tau_mem = 1; %membrane time constant [ms]
tau_refractory = 25; %refractory period membrane time constant [ms]
factor_refractory = 2; %multiple of tau_refractory until tau changes back, after a spike (~2 to 4) 
tau = tau_mem;
%Vr_exc = 20; %[mV]
Vr_inh = -60; %[mV]
Vh_gap = 45; %holding potential for gap junction current
t_vect = t_start:dt:t_end; %will hold vector of times
refractoryTimer = 0;

%Pure Inhibition
dataMatrixpureInh = dataMatrixInh;
dataMatrixpureInh(:, t_vect>t_StimStart & t_vect<t_StimEnd) = dataMatrixInh(:, t_vect>t_StimStart & t_vect<t_StimEnd) - dataMatrixGap(:, t_vect>t_StimStart & t_vect<t_StimEnd);

%g_dataMatrixExc = dataMatrixExc./(-80);
g_dataMatrixpureInh = dataMatrixpureInh./80;

N_epochs = length(dataMatrixpureInh(:,1));
t_vect = t_start:dt:t_end; %will hold vector of times

%Baseline subtraction
for epoch = 1:N_epochs
    bl = mean(dataMatrixGap(epoch, t_vect<t_StimStart));
    dataMatrixGap(epoch,:) = dataMatrixGap(epoch,:) - bl;
    
    bl = mean(dataMatrixpureInh(epoch, t_vect<t_StimStart));
    dataMatrixpureInh(epoch,:) = dataMatrixpureInh(epoch,:) - bl;
end;

%Gaussian current noise
% I_noise = randn(1,length(dataMatrixpureInh(1,:)));
% noiseSD = std(dataMatrixInh);
% I_noise = I_noise.*noiseSD;

spikeTimes = [];

%N_epochs = 1;
for epoch = 1:N_epochs
    V_vect = zeros(1,length(t_vect)); %initialize the voltage vector
    %initializing vectors makes your code run faster!
    V_plot_vect = zeros(1,length(t_vect)); %pretty version of V_vect to be plotted, that displays a spike
    % whenever voltage reaches threshold
    %INTEGRATE THE EQUATION tau*dV/dt = -V + E_L + I_e*R_m
    
    V_vect(1)= E_L; %first element of V, i.e. value of V at t=0
    V_plot_vect(1) = V_vect(1); %if no spike, then just plot the actual voltage V
    
    I_e_vect = zeros(1, t_end-t_start/dt);
    
    NumSpikes = 0; %holds number of spikes that have occurred
    for i = 1:length(t_vect)-1 %loop through values of t in steps of dt ms
        I_e_vect(i) = dataMatrixGap(epoch,i) + (V_vect(i) - Vr_inh)*g_dataMatrixpureInh(epoch,i);
        V_vect(i+1) = V_vect(i) + (dt/tau)*(E_L - V_vect(i) - (I_e_vect(i)*R_m*1e-3)); %minus on I_e_vect(i), for inward current >0
        %         V_inf = E_L + I_e_vect(i)*R_m; %value that V_vect is exponentially
        %         %decaying towards at this time step
        %         %next line does the integration update rule
        if (V_vect(i+1) > V_th) %cell spiked
            %Change tau and start refractory timer
            tau = tau_refractory;
            refractoryTimer = tau_refractory*factor_refractory;
            V_vect(i+1) = V_reset; %set voltage back to V_reset
            V_plot_vect(i+1) = V_spike; %set vector that will be plotted to show a spike here 
            NumSpikes = NumSpikes + 1; %add 1 to the total spike count
            spikeTimes = [spikeTimes,t_vect(i+1)]; 
        else %voltage didn't cross threshold so cell does not spike
            if refractoryTimer > 0 % step refractory timer if active
                
                refractoryTimer = refractoryTimer-dt;
            else
                
                tau = tau_mem;
            end;
            V_plot_vect(i+1) = V_vect(i+1); %plot the actual voltage
        end
    end
    
    AveRate_vect(epoch) = 1000*NumSpikes/(t_StimEnd - t_StimStart); %gives average firing %rate in [#/sec = Hz]
    %MAKE PLOTS
    
%     I_Stim_vect = 1;
%     figure(1)
%     subplot(N_epochs,1,epoch)
%     plot(t_vect, V_plot_vect);
%     if (epoch == 1)
%         title('Voltage vs. time');
%     end
%     if (epoch == length(I_Stim_vect))
%         xlabel('Time (ms)');
%     end
%     ylabel('Voltage (mV)');
figure;
plot(t_vect, V_plot_vect);
xlabel('Time (ms)');
ylabel('Voltage (mV)');
end

%PSTH
bnSz = 20; %[ms]
timeAxis_PSTH = (t_start:bnSz:t_end-bnSz);
PSTH = hist(spikeTimes,timeAxis_PSTH+round(bnSz/2))./bnSz.*1000./N_epochs;
figure;
plot(timeAxis_PSTH./1000,PSTH);
xlabel('Time (ms)');
ylabel('Spike rate (Hz)');