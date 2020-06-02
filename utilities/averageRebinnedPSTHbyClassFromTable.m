function PSTHstruct = averageRebinnedPSTHbyClassFromTable(tab)
%PSTH is nClasses-by-1 structure with fields:
%   className
%   mean
%   std
%   spotSizeVec
%   timeVec

%initialize

%types to combine
ON_DS.className = 'ON DS combined';
ON_DS.components = {'ON DS - direction unknown', ...
    'ON DS dorsonasal', ...
    'ON DS temporal', ...
    'ON DS ventronasal'};

OODS.className = 'OODS combined';
OODS.components = {'ON-OFF DS - direction unknown', ...
    'ON-OFF DS dorsal', ...
    'ON-OFF DS nasal', ...
    'ON-OFF DS temporal', ...
    'ON-OFF DS ventral'};

classesUnique = unique(tab{:,3});
nClasses = numel(classesUnique);
empty = cell(nClasses,1);
PSTHstruct = struct('className',empty,'mean',empty,'std',empty);
data = tab{:,4}; %a cell array of PSTHs
timeVec = tab{:,5}; %a cell array of peristimulus times matching the PSTHs
sizeVec = tab{:,6}; %a cell array of spot sizes matching the PSTHs
sizeBins = logspace(1,log10(1200),20); %an example list of desired spot sizes;
timeRange = [-1 2]; %truncate/pad data to this time range;
keyboard;
[rebinnedData,binIdx] = rebinData(data,sizeVec,sizeBins,timeVec,timeRange); %returns a cell array of uniform PSTHs, and the spot sizes which were used to make them
nSizes = size(sizeBins,2);
nTimes = size(-1:.01:2,2);

pause;
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

className = ON_DS.className;
subTab = [];
for i=1:length(ON_DS.components)
    subTab = [subTab; rebinnedData(strcmp(tab{:,3},ON_DS.components{i}),:)];
end

fullPSTH=permute(reshape(cell2mat(subTab),nSizes,[],nTimes),[1 3 2]);

PSTHstruct(n+1).className = {className};
PSTHstruct(n+1).mean = nanmean(fullPSTH,3);
PSTHstruct(n+1).std = std(fullPSTH,1,3); %sample std, with nans where undefined

className = OODS.className;
subTab = [];
for i=1:length(OODS.components)
    subTab = [subTab; rebinnedData(strcmp(tab{:,3},OODS.components{i}),:)];
end

fullPSTH=permute(reshape(cell2mat(subTab),nSizes,[],nTimes),[1 3 2]);

PSTHstruct(n+2).className = {className};
PSTHstruct(n+2).mean = nanmean(fullPSTH,3);
PSTHstruct(n+2).std = std(fullPSTH,1,3); %sample std, with nans where undefined

end
