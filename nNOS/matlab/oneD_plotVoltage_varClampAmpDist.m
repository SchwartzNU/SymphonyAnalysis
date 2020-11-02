%cd to simulation directory ('E:/oneD/sim062317b')
curdir = pwd;
cd('oneD_out_loop');
Distance=0:5:100;
Amp = 5:5:200;
for i = 1:numel(Distance)
    for j = 1:numel(Amp)
        fname=sprintf('%dum_%dpA_closed.dat',Distance(i),Amp(j));
        f=fopen(fname);
        Header=textscan(f,'%f',23,'Delimiter',' ');
        tempDat=textscan(f,'%f %f');
        OutDat(i,j,:,1,1)=tempDat{1}(1:end/2);
        OutDat(i,j,:,2,1)=tempDat{1}(end/2+1:end);
        OutDat(i,j,:,1,2)=tempDat{2}(1:end/2);
        OutDat(i,j,:,2,2)=tempDat{2}(end/2+1:end);
        fclose(f);
    end
end

%%%%%%%%%%%%%%%%%%

S=size(OutDat,3);

for i = 1:numel(Distance)
    FigDat{i,1}=squeeze(cat(3,OutDat(i,:,ceil(S/2+Distance(i)):-1:floor(S/2),1,2),OutDat(i,:,floor(S/2):S,2,2)))';
    FigDat{i,2}=squeeze(cat(3,-1*OutDat(i,:,ceil(S/2+Distance(i)):-1:floor(S/2),1,1),OutDat(i,:,floor(S/2):S,2,1)))';
end
cd(curdir);
%FigDat is a numel(Distance)-by-2 cell
%Each element of FigDat is an x-by-numel(Amp) matrix where x is length(cable)/2 + distance(clamp-to-junction)
%The first column of FigDat is the voltage values, the second is location (um)

%There is some weird behavior at 1000um
%This is related to the fact that I reduced the sampling rate at this distance
%I think it is because the locations are off, not the voltages
%i.e. I think it's plotting the voltage at the beginning of the section whereas it's measured at the middle of the section