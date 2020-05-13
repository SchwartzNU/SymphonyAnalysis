function [pVals, Gmatch_mean, Rdiff_mean, Gmatch_sd, Rdiff_sd, CC_mean, CC_sd] = readModelSetResults(rootDir)

D = dir(rootDir);
Rin = [];
CC = [];
all_Rdiff = [];
GJ_Rvals = [1e10,1e5,5e4,1e4,5e3,1e3,9e2,8e2,7e2,6e2,5e2,4e2,3e2,2e2,100,50,20];
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
        
        %load([rootDir filesep curName filesep 'network.mat']);
        %all_NGJ(z) = nGJ;
        
        %read in .rinput and .cc files
        Rvec = zeros(1,N);
        for r=1:N
            fname = [rootDir filesep curName filesep 'gap' num2str(r) '.rinput'];
            temp = dlmread(fname);
            Rvec(r) = median(temp);
        end
        [~, ind] = min(abs(Rvec-darkResistance));
        all_Rmatch(z) = GJ_Rvals(ind);
        fname = [rootDir filesep curName filesep 'gap' num2str(ind) '.rinput'];
        temp = dlmread(fname);
        Rin{z} = temp;
        all_Rdiff(z) = median(temp) - darkResistance;
        
        fname = [rootDir filesep curName filesep 'gap' num2str(ind) '.cc'];
        CC{z} = dlmread(fname);
        
        % plot segment of parameter space in which both CC and Rinput are
        % close to correct
        % space is GJ density vs. GJ conductance
        
        z=z+1;
    end
 
end

pVals = sort(unique(all_pVals));
L = length(pVals);
Gmatch_mean = zeros(1,L);
Rdiff_mean = zeros(1,L);
Gmatch_sd = zeros(1,L);
Rdiff_sd = zeros(1,L);
CC_mean = zeros(1,L);
CC_sd = zeros(1,L);

for i=1:L
   ind = all_pVals==pVals(i);
   Gmatch_mean(i) = mean(1E3./all_Rmatch(ind));
   Rdiff_mean(i) = mean(all_Rdiff(ind));
   Gmatch_sd(i) = std(1E3./all_Rmatch(ind));
   Rdiff_sd(i) = std(all_Rdiff(ind));
   CCpart = cell2mat(CC(ind)');
   CC_mean(i) = mean(CCpart);
   CC_sd(i) = std(CCpart);
end

