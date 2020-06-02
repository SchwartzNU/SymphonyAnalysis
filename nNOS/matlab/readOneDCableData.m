function [loc1Mat_D, V1Mat_D, loc2Mat_D, V2Mat_D, loc1Mat_L, V1Mat_L, loc2Mat_L, V2Mat_L, V1max_D, V1max_L, V2max_D, V2max_L] = readOneDCableData()
Lvec = [20, 40, 80, 160, 320];
Ivec = [5:5:100];
divPoint = 4084;

nL = length(Lvec);
nI = length(Ivec);
loc1Mat_D = cell(nL,nI);
V1Mat_D = cell(nL,nI);
loc2Mat_D = cell(nL,nI);
V2Mat_D = cell(nL,nI);
V1max_D = zeros(nL,nI);
V2max_D = zeros(nL,nI);


loc1Mat_L = cell(nL,nI);
V1Mat_L = cell(nL,nI);
loc2Mat_L = cell(nL,nI);
V2Mat_L = cell(nL,nI);
V1max_L = zeros(nL,nI);
V2max_L = zeros(nL,nI);

for l=1:nL
    for i=1:nI
        fname = [num2str(Lvec(l)) 'um_' num2str(Ivec(i)) 'pA_dark.dat']
        f=fopen(fname);
        Header=textscan(f,'%f',28,'Delimiter',' ');
        tempDat=textscan(f,'%f %f');
                
        loc1 = tempDat{1}(1:divPoint-1) + Lvec(l)/2;
        V1 = tempDat{2}(1:divPoint-1);
        loc2 = tempDat{1}(divPoint:end) + Lvec(l)/2;
        V2 = tempDat{2}(divPoint:end);
        
        ind = loc1>=0;
        loc1 = loc1(ind);
        V1 = V1(ind);
        
        % Ca1 = Ca_fit(V1);
        % Ca1 = Ca1./max(Ca1);
        
        ind = loc2>=0;
        loc2 = loc2(ind);
        V2 = V2(ind);
        
        loc1Mat_D{l,i} = loc1;
        V1Mat_D{l,i} = V1;
        loc2Mat_D{l,i} = loc2;
        V2Mat_D{l,i} = V2;
        V1max_D(l,i) = max(V1);
        V2max_D(l,i) = max(V2);
        
        fclose(f);        
        
        fname = [num2str(Lvec(l)) 'um_' num2str(Ivec(i)) 'pA_light.dat'];
        f=fopen(fname);
        Header=textscan(f,'%f',28,'Delimiter',' ');
        tempDat=textscan(f,'%f %f');
                
        loc1 = tempDat{1}(1:divPoint-1) + Lvec(l)/2;
        V1 = tempDat{2}(1:divPoint-1);
        loc2 = tempDat{1}(divPoint:end) + Lvec(l)/2;
        V2 = tempDat{2}(divPoint:end);
        
        ind = loc1>=0;
        loc1 = loc1(ind);
        V1 = V1(ind);
        
        % Ca1 = Ca_fit(V1);
        % Ca1 = Ca1./max(Ca1);
        
        ind = loc2>=0;
        loc2 = loc2(ind);
        V2 = V2(ind);
        
        loc1Mat_L{l,i} = loc1;
        V1Mat_L{l,i} = V1;
        loc2Mat_L{l,i} = loc2;
        V2Mat_L{l,i} = V2;
        
        V1max_L(l,i) = max(V1);
        V2max_L(l,i) = max(V2);
        
        fclose(f);  
    end
end


%Ca_fit = fittedmodel;


%keyboard;


% Ca2 = Ca_fit(V2);
% Ca2 = Ca2./max(Ca1);
%
% figure(2);
% subplot(2,2,1);
% plot(loc1,V1,'b');
% xlabel('Location (microns)');
% ylabel('Voltage (mV)');
% subplot(2,2,3);
% plot(loc1,Ca1,'r');
% xlabel('location (microns)');
% ylabel('[Ca] (norm.)');
% subplot(2,2,2);
% plot(loc2,V2,'b');
% xlabel('Location (microns)');
% ylabel('Voltage (mV)');
% subplot(2,2,4);
% plot(loc2,Ca2,'r');
% xlabel('location (microns)');
% ylabel('[Ca] (norm.)');


%%%%%%%%%%%%%%%%%%

% S=size(OutDat,1);
% V = squeeze(cat(3,OutDat(:,ceil(S/2+Distance(i)):-1:floor(S/2),1,2),OutDat(:,floor(S/2):S,2,2)))';
% loc = squeeze(cat(3,-1*OutDat(:,ceil(S/2+Distance(i)):-1:floor(S/2),1,1),OutDat(i,:,floor(S/2):S,2,1)))';
%
% FigDat{i,1}=squeeze(cat(3,OutDat(i,:,ceil(S/2+Distance(i)):-1:floor(S/2),1,2),OutDat(i,:,floor(S/2):S,2,2)))';
% end

%FigDat is a numel(Distance)-by-2 cell
%Each element of FigDat is an x-by-numel(Amp) matrix where x is length(cable)/2 + distance(clamp-to-junction)
%The first column of FigDat is the voltage values, the second is location (um)

%There is some weird behavior at 1000um
%This is related to the fact that I reduced the sampling rate at this distance
%I think it is because the locations are off, not the voltages
%i.e. I think it's plotting the voltage at the beginning of the section whereas it's measured at the middle of the section