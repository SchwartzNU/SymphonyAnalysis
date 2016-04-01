function M = LMnormalize(M)
%normalize each row

rowMeans = nanmean(M,2);
Gmean = nanmean(rowMeans);

for i=1:size(M,1)
   M(i,:) =  M(i,:) + (Gmean-rowMeans(i));
end
