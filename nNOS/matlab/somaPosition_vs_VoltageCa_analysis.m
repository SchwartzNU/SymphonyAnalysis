Nfiles=36;
allLines={};
somaPos=[];
% seed = makeNetworkMATLAB/ModelNetworks/varyGJDensity/density=300_seed=1
networkFolder = 'makeNetworkMATLAB\ModelNetworks\varyGJDensity\density=300_seed=1\';
%stimFile = 'R:\\Ophthalmology\Research\SchwartzLab\nNOS Model\SpotStimLoop_40um\x-33y233.txt';
stimFile = 'x-33y233';

% load from seed, separate lines by cell
for i=1:Nfiles
    fname = sprintf('%s%.4d.dat',networkFolder,i);
    fid = fopen(fname, 'r');
    curLine = fgetl(fid);
    temp=str2num(curLine);
    somaPos(i,:)=temp(1:2);
    allLines{i}=[];
    while(curLine>0)
        allLines{i}=cat(1,allLines{i},str2num(curLine));
        curLine = fgetl(fid);
    end
    fclose(fid);
end
[pX,pY]=linesToSegmentPositions(allLines,200);

% run pointInputModel from seed to gen voltages
fid=  fopen('curStim.txt', 'w');
fprintf(fid,'%s\r',stimFile);
fclose(fid);
fid=  fopen('curFolder.txt', 'w');
fprintf(fid,'%s\r',networkFolder);
fclose(fid);

fprintf('Running NEURON simulation...\n');
%system('C:\nrn\\bin\nrniv.exe -nogui pointInputModel.hoc', '-echo')
system('C:\Users\Zach\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\NEURON 7.4x86_64\nrngui.exe -nogui pointInputModel.hoc', '-echo')
%system command hanging in the middle of continuerun()
%importdata: VmaxLight and VmaxDark
VmaxLight=dlmread(sprintf('SpotStimLoop_40um\\%s_Vmax_output_light.txt',stimFile));
VmaxDark=dlmread(sprintf('SpotStimLoop_40um\\%s_Vmax_output_dark.txt',stimFile));
VmaxLight=VmaxLight(:);
VmaxDark=VmaxDark(:);
% run sigmoid from voltages
% plot voltages, Ca by cell soma pos

sP=[];
for n=1:numel(allLines)
    sP=cat(1,sP,repmat(allLines{n}(1,1:2),200*size(allLines{n},1),1));
end

sD=sqrt((pX-sP(:,1)).^2+(pY-sP(:,2)).^2);


