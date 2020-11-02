function [R_in, CC, gapC] = readRmAndCCFromNetwork(networkDir, gapRVec)
L = length(gapRVec);
R_in = zeros(1,L);
CC = zeros(1,L);
gapC = 1./(gapRVec*1E6); %in pS

for i=1:L
    fname_rm = [networkDir filesep 'gap' num2str(i) '.rinput'];           
    fname_cc = [networkDir filesep 'gap' num2str(i) '.cc'];  
    
    f_r = fopen(fname_rm);    
    rvals = textscan(f_r,'%f');
    rvals = rvals{1};
    fclose(f_r);
    R_in(i) = mean(rvals);
    
    f_cc = fopen(fname_cc);    
    ccvals = textscan(f_cc,'%f');
    ccvals = ccvals{1};
    fclose(f_cc);
    CC(i) = mean(ccvals);    
end


