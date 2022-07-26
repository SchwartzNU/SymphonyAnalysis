function feat = rebinData(data,sizeVec,sizes,timeVec,time,dt)
% Given a cell array of PSTH data matrices, a corresponding cell array of
% sizeVecs, a D-by-2 matrix timeVec of start and end times of each recording, and
% the binning time width dt, returns the D-by-R features matrix corresponding to
% the R-many (sizes,time) subscript pairs for each cell, using nearest neighbors
% interpolation and extrapolation.
% Note that time must be R-by-1 and sizes must by 1-by-R.

% solves the problem efficiently by imputing each dimension sequentially,
% which is possibly due to the structure of the recording

%get the problem size
nD = numel(data);
if nD ==0
   feat =[];
   return
end

nR = numel(sizes);

%keyboard;
%convert the desired times to indices for each cell
tInd = round(bsxfun(@minus,time',timeVec(:,1))/dt+1);
% uint16 is used to negotiate rounding?

%if we're asking for an index before the start, that means we need to
%extrapolate from the first time point
tInd(tInd<1)=1;

%we will output the result as feat
feat = zeros(nD,nR);
%i = zeros(nR,1,'uint16');
%s = zeros(nR,1,'uint16');
for n=1:nD %for each cell
    d = data{n}; %grab the data
    
    [nS,nT] = size(d); %how many points did we record?
    
    i = tInd(n,:)'; %grab the desired times
    i(i>nT) = nT; %if we're asking for an index after the end, extrapolate from the end
    %note that it's much faster to impute in the time dimension since we
    %know that we've recorded at every dt between the start and end
    %keyboard;

    [~,s] = min(abs(bsxfun(@minus,sizeVec{n},sizes')),[],2);
    %assign s to the nearest spot size that we recorded
    %note that if two spot sizes are tied, we take the smaller spot size
    %this is convenient but also logical, since cell behavior tends to
    %change more rapidly at larger spot sizes
    
    
    %feat(n,:) = d(sub2ind([nS nT],s,i));
    keyboard;
    feat(n,:) = d ( s + nS*(i-1) );
    %convert the paired subscripts into linear indices, and assign the
    %corresponding data to feat
end


end
