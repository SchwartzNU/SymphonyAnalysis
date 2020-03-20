function PSTHstruct = averageRebinnedPSTHbyClassFromTable(tab)
%PSTH is nClasses-by-1 structure with fields:
%   className
%   mean
%   std
%   spotSizeVec
%   timeVec

%initialize
classesUnique = unique(tab{:,3});
nClasses = numel(classesUnique);
empty = cell(nClasses,1);
PSTHstruct = struct('className',empty,'mean',empty,'std',empty);
data = tab{:,4}; %a cell array of PSTHs
timeVec = tab{:,5}; %a cell array of peristimulus times matching the PSTHs
sizeVec = tab{:,6}; %a cell array of spot sizes matching the PSTHs
sizeBins = [5 10 20 50 100 200 500 1000]; %an example list of desired spot sizes;
timeRange = [-1 2]; %truncate/pad data to this time range;
[rebinnedData,binIdx] = rebinData(data,sizeVec,sizeBins,timeVec,timeRange); %returns a cell array of uniform PSTHs, and the spot sizes which were used to make them
nSizes = size(sizeBins,2);
nTimes = size(-1:.01:2,2);

%tab{:,4} = rebinnedData;
%[timeVec{:}] = deal(-1:.01:2);
%tab{:,5} = timeVec;
%[sizeVec{:}] = deal(sizeBins);
%tab{:,6} = sizeVec;

%loop through classes
for n=1:nClasses
    className = classesUnique(n);
    
    %grab the subset of the table corresponding to this class
    subTab = rebinnedData(strcmp(tab{:,3},className),:);
    
    fullPSTH=permute(reshape(cell2mat(subTab),nSizes,[],nTimes),[1 3 2]);
    
    %cleanup
    PSTHstruct(n).className = className;
    PSTHstruct(n).mean = nanmean(fullPSTH,3);
    PSTHstruct(n).std = std(fullPSTH,1,3); %sample std, with nans where undefined
    %PSTHstruct(n).spotSizeVec = spotSizeVec;
    %PSTHstruct(n).timeVec = timeVec;
end

end
