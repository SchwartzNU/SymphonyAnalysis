function [Rin, CCmat, CCvec, CC_all] = readModelResultsAcrossSeeds(rootDir, Nseeds)

GJ_Rvals = [1e10,1e5,5e4,1e4,5e3,1e3,9e2,8e2,7e2,6e2,5e2,4e2,3e2,2e2,100,50,20];
N = length(GJ_Rvals);

Rin = zeros(Nseeds,N);
CCvec = zeros(Nseeds,1);
CC_all = [];

%read in .rinput and .cc files
for i=1:Nseeds
    fid = fopen('curFolder.txt', 'w');
    curName = [rootDir '_seed=' num2str(i)];
    fprintf(fid,'%s\r', curName);
    fclose(fid);
    
    [~, Rmat, CCmat, CC] = readSingleModelResults(curName, GJ_Rvals);
    CC_all = [CC_all; CC];
    CCvec(i) = median(CC);
    Rin(i,:) = median(Rmat);
end
CCmat = CCmat([1:20, 22:end], :);

