function [pVals, NGJ_mean, NGJ_sd, Rin_mean, Rin_sd, CC_mean, CC_sd] = getConnectivityVsNetworkParam(rootDir)

D = dir(rootDir);
Rin = [];
CC = [];
GJ_Rvals = [1e10,1e5,5e4,1e4,5e3,4e3,3e3,2e3,1e3,5e2,1e2,1e1,1];
N = length(GJ_Rvals); %number of gap and cc files for each folder 
darkResistance = 180;

z=1;
for i=1:length(D)
    curName = D(i).name;
    if ~strcmp(curName(1), '.');     
        curName
        temp = strsplit(curName, '_');
        paramStr = temp{1};
        seedStr = temp{2};
        
        temp = strsplit(paramStr, '=');
        all_pVals(z) = str2num(temp{2});
        
        temp = strsplit(seedStr, '=');
        all_seeds(z) = str2num(temp{2});
        
        load([rootDir filesep curName filesep 'network.mat']);
        all_NGJ(z) = nGJ;
        
        %read in .rinput and .cc files
        for i=1:N
        Rin{z} = dlmread(
        % interpolate to dark value of Rinput (or choose closest one) and
        % report CC
        % plot segment of parameter space in which both CC and Rinput are
        % close to correct
        % space is GJ density vs. GJ conductance
        
        
        z=z+1;
    end
 
end

pVals = sort(unique(all_pVals));
L = length(pVals);
NGJ_mean = zeros(1,L);
NGJ_sd = zeros(1,L);
for i=1:L
   ind = all_pVals==pVals(i);
   NGJ_mean(i) = mean(all_NGJ(ind));
   NGJ_sd(i) = std(all_NGJ(ind));
end

