function [peaks,Ind] = getPeaks(X,dir)
if dir > 0 %local max
    Ind = find(diff(diff(X)>0)<0)+1;
    if isempty(Ind)
        Ind = find(max(X)); %for rare occurence when spike peak can't be determined by differentials.
        warning('Trouble detecting spike amplitude')
    end
else %local min
    Ind = find(diff(diff(X)>0)>0)+1;
    if isempty(Ind)
        Ind = find(min(X)); %for rare occurence when spike peak can't be determined by differentials.
        warning('Trouble detecting spike amplitude')
    end
end
peaks = X(Ind);