function [Rmatch, Rmat, CCmat, CC] = readSingleModelResults(rootDir, GJ_Rvals)

Ncells = 36;
N = length(GJ_Rvals); %number of gap and cc files
darkResistance = 180;

Rmat = zeros(Ncells,N);
CCmat = zeros(Ncells,N);
Rvec = zeros(1,N);
%read in .rinput and .cc files
for r=1:N
    fname = [rootDir filesep 'gap' num2str(r) '.rinput'];
    Rmat(:,r) = dlmread(fname);
    Rvec(r) = median(Rmat(:,r));
    
    fname = [rootDir filesep 'gap' num2str(r) '.cc'];
    CCmat(:,r) = dlmread(fname);
end
[~, ind] = min(abs(Rvec-darkResistance));
Rmatch = GJ_Rvals(ind);

fname = [rootDir filesep 'gap' num2str(ind) '.cc'];
CC = dlmread(fname);


