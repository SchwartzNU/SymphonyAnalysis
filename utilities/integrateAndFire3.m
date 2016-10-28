function [OSI,DSI] = IntegrateandFire(shuffle,cellname) 

%DEFINE PARAMETERS
dt = 0.1; %time step [ms]
t_start = 0;
t_end = 250; %total time of run [ms]
t_StimStart = 0; %time to start injecting current [ms]
t_StimEnd = 250; %time to end injecting current [ms]
E_L = -60; %resting membrane potential [mV]
V_th = -58; %spike threshold [mV] -20
V_reset = -70; %value to reset voltage to after a spike [mV]
V_spike = 20; %value to draw a spike to, when cell spikes [mV]
R_m = 500; %membrane resistance [MOhm]
tau_mem = 1; %membrane time constant [ms]
tau_refractory = 10; %refractory period membrane time constant [ms]
factor_refractory = 2; %multiple of tau_refractory until tau changes back, after a spike (~2 to 4) 
tau = tau_mem;
%Vr_exc = 20; %[mV]
Vr_inh = -60; %[mV]
Vh_gap = 45; %holding potential for gap junction current
t_vect = t_start:dt:t_end; %will hold vector of times
refractoryTimer = 0;

%Extract data from Analysis Tree
nodes = length(analysisTree.Node);
for i = 1:nodes
    if isfield(analysisTree.Node{i},'class')
        if strcmp(analysisTree.Node{i}.class,'DriftingGratingsAnalysis')  %check for Drifting Gratings Data     
            if strcmpi(analysisTree.Node{i,1}.ampMode,'Whole cell')  %check for whole cell data
                if (analysisTree.Node{i,1}.ampHoldSignal < 0)   %Excitation or Gap junction
                    %Vh_exc = analysisTree.Node{i,1}.ampHoldSignal; %holding potential for excitatory current
                    gratingAngle = analysisTree.Node{i+3,1}.gratingAngle;
                    Nangles = length(analysisTree.Node{i+3,1}.gratingAngle);
                    GapData = zeros(Nangles,length(analysisTree.Node{i+4,1}.cycleAvg_y.value));
                    angles_shuffled = randperm(Nangles);
                    for j = 1:Nangles
                        GapData(j,:) = analysisTree.Node{i+3+j,1}.cycleAvg_y.value; %store all gap junction currents
                    end
                end
                
                if (analysisTree.Node{i,1}.ampHoldSignal > 0)   %Inhibition
                    Vh_inh = analysisTree.Node{i,1}.ampHoldSignal; %holding potential for inhibitory current
                    InhData = zeros(Nangles,length(analysisTree.Node{i+4,1}.cycleAvg_y.value));
                    for j = 1:Nangles
                        InhData(j,:) = analysisTree.Node{i+3+j,1}.cycleAvg_y.value; %store all inhibitory currents
                    end
                end
            end
        end
    end
end

%Pure Inhibition
pureInhData = InhData;
pureInhData(:, t_vect>t_StimStart & t_vect<t_StimEnd) = InhData(:, t_vect>t_StimStart & t_vect<t_StimEnd) - GapData(:, t_vect>t_StimStart & t_vect<t_StimEnd);

%Randomize Data
prompt = 'Randomize angles for inhibitory currents? [Y/N] ';
str = input(prompt,'s');
if strcmpi(str,'Y')
    pureInhData = pureInhData(randperm(size(pureInhData,1)),:);
end
prompt = 'Randomize angles for gap junction currents? [Y/N] ';
str = input(prompt,'s');
if strcmpi(str,'Y')
    GapData = GapData(randperm(size(GapData,1)),:);
end

%Conductance data
%mV/MOhm = nA => need currents in nA not pA.
%*1e-3 = conversion pA to nA
%I = g(V-Vr) was taken in voltage clamp +20mV, -60mV, hence 1/(-80mV)
%load('/Users/adammani/Documents/analysis/Adam Matlab analysis/09Sep2015/mat files/ON delayed/dataForLIF_LS100215Bc1.mat');
%g_dataMatrixExc = dataMatrixExc.*1e-3/(-80);
g_pureInh = pureInhData./(Vh_inh - Vr_inh);
% g_meanDataExc = meanDataExc.*1e-3/(-80);
% g_meanDataInh = meanDataInh.*1e-3/80;

%Baseline subtraction
for epoch = 1:Nangles
    %bl = mean(dataMatrixGap(epoch, t_vect<t_StimStart));
    %dataMatrixGap(epoch,:) = dataMatrixGap(epoch,:) - bl;
    
%     bl = mean(g_dataMatrixpureInh(epoch, t_vect<t_StimStart));
%     g_dataMatrixpureInh(epoch,:) = g_dataMatrixpureInh(epoch,:) - bl;
%     
%     bl_gj = mean(dataMatrixGap(epoch, t_vect<t_StimStart));
%     dataMatrixGap(epoch,:) = dataMatrixGap(epoch,:) - bl_gj;
end
% bl = mean(g_meanDataExc(t_vect<t_StimStart));
% g_meanDataExc = g_meanDataExc - bl;
% bl = mean(g_meanDataInh(t_vect<t_StimStart));
% g_meanDataInh = g_meanDataInh - bl;

%N_epochs = 1;
F1amplitude = zeros(1,Nangles);
for angle = 1:Nangles
    spikeTimes = [];
    %g_exc = g_dataMatrixExc(epoch,:);
    g_inh = g_pureInh(angle,:);
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
        I_e_vect(i) = GapData(angle, i) + (V_vect(i) - Vr_inh)*g_inh(i);
        V_vect(i+1) = V_vect(i) + (dt/tau)*(E_L - V_vect(i) - (I_e_vect(i)*R_m*1e-3)); %minus on I_e_vect(i), for inward current >0
        %keyboard;
        %if statement below says what to do if voltage crosses threshold
        if (V_vect(i+1) > V_th) %cell spiked
            %Change tau and start refractory timer
            tau = tau_refractory;
            refractoryTimer = tau_refractory*factor_refractory;
            % % %
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
    
    %AveRate_vect(epoch) = 1000*NumSpikes/(t_StimEnd - t_StimStart); %gives average firing %rate in [#/sec = Hz]
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
    %figure;
    %plot(t_vect, V_plot_vect);
    %xlabel('Time (ms)');
    %ylabel('Voltage (mV)');

    %PSTH
    bnSz = 20; %[ms]
    timeAxis_PSTH = (t_start:bnSz:t_end-bnSz);
    PSTH = hist(spikeTimes,timeAxis_PSTH+round(bnSz/2))*1000./bnSz;
    %figure;
    %plot(timeAxis_PSTH,PSTH);
    %xlabel('Time (ms)');
    %ylabel('Spike rate (Hz)');

    %Calculate F1 and F2 amplitudes
    ft = fft(PSTH);
    F1amplitude(1,angle) = abs(ft(2))/length(ft)*2;
    
end

%Calculate DSI and OSI
R=0;
RDirn=0;
ROrtn=0;
for j=1:Nangles
    R=R+F1amplitude(j);
    RDirn = RDirn + (F1amplitude(j)*exp(sqrt(-1)*gratingAngle(j)*pi/180));
    ROrtn = ROrtn + (F1amplitude(j)*exp(2*sqrt(-1)*gratingAngle(j)*pi/180));
end
            
DSI = abs(RDirn/R);
OSI = abs(ROrtn/R);
clear angle
DSang = angle(RDirn/R)*180/pi;
OSang = angle(ROrtn/R)*90/pi;
            
if DSang < 0
    DSang = 360 + DSang;
end
            
if OSang < 0
    OSang = 360 + OSang;
end

%Plot polar plots
F1amplitude = [F1amplitude,F1amplitude(1)];
gratingAngle = [gratingAngle,gratingAngle(1)];

figure;
polar(gratingAngle*pi/180,F1amplitude);
hold on;
polar([0 DSang*pi/180], [0 (100*DSI)], 'r-');
polar([0 OSang*pi/180], [0 (100*OSI)], 'g-');
xlabel('barAngle');
ylabel('F1 amplitude');
title(['DSI = ' num2str(DSI) ', DSang = ' num2str(DSang) ' and OSI = ' num2str(OSI) ', OSang = ' num2str(OSang)]);
hold off;

end