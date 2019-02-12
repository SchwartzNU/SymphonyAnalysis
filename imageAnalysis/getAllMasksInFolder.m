function [R, Rmean, Rsd, Rerr] = getAllMasksInFolder(H, N, Ncolor)
Rmean = ones(N+1, Ncolor) * nan;
Rsd = ones(N+1, Ncolor) * nan;
Rerr = ones(N+1, Ncolor) * nan;

%bgColor = getMeanColorFrom2DMask(H, 'bg.tif');

for i=0:N
    if exist(['p' num2str(i) '.tif'])
        disp(['Processing mask ' num2str(i) ' of ' num2str(N)]);        
        curR = getSpectralSignatureFromMask(H, ['p' num2str(i) '.tif'], []);
        temp = sum(mean(curR));
        %curR = curR ./ sum(temp);
        R{i+1} = curR;           
        Rmean(i+1, :) = mean(curR) ./ temp;
        Rsd(i+1, :) = std(curR ./ temp, [], 1);
        Rerr(i+1, :) = std(curR ./ temp, [], 1) ./ sqrt(size(curR, 1));
    end
end
