function PSTHstruct = averagePSTHbyClassFromTable(tab)
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
PSTHstruct = struct('className',empty,'mean',empty,'std',empty,'spotSizeVec',empty,'timeVec',empty);


%loop through classes
for n=1:nClasses
    className = classesUnique(n);
    
    %grab the subset of the table corresponding to this class
    subTab = tab(strcmp(tab{:,3},className),:);
    
    %find all the unique time points
    timeVec = unique(round(cell2mat(subTab{:,5}')*100)/100)';
    %machine precision issues with the time step necessitates rounding
    
    %do the same for the spot sizes
    spotSizeVec = unique(cell2mat(subTab{:,6}'))';
    
    psth = subTab{:,4};
    
    %we are going to pad the PSTH with nans to achieve consistent size 
    fullPSTH = cell(size(psth));
    [fullPSTH{:}] = deal(nan(numel(timeVec),numel(spotSizeVec)));
    
    %this function will place the PSTHs into the correct "pixels"
    %note that cellfun is essentially a pre-compiled for-loop
    fullPSTH = cellfun(@(a,b,c,d) reassignVals(a,b,c,d),fullPSTH,subTab{:,5},subTab{:,6},psth,'uniformoutput',false);
    fullPSTH = cell2mat(shiftdim(fullPSTH,-2)); %cleans up the data dimensions
    %PSTHs are now time-by-size-by-cell matrix with nan-padding 
    % note that if we want to rebin the spot sizes we ought to do so here,
    % or else save out the full PSTH matrix
    
    %cleanup
    PSTHstruct(n).className = className;
    PSTHstruct(n).mean = nanmean(fullPSTH,3);
    PSTHstruct(n).std = std(fullPSTH,1,3); %sample std, with nans where undefined
    PSTHstruct(n).spotSizeVec = spotSizeVec;
    PSTHstruct(n).timeVec = timeVec;
end


    function a = reassignVals(a,b,c,d)
        
        if isempty(b) || isempty(c) || isempty(d)
            % the data for this cell is missing, so we will ignore it
            a=[];
            return
        end
        
        %find the correspondence between this cell's time-spot pairs and
        %the fullPSTH matrix
        [~,b] = ismember(round(b*100)/100,timeVec);
        [~,c] = ismember(c,spotSizeVec);
        
        s = substruct('()',{b,c});
        a = subsasgn(a,s,d');
        %efficiently performs the operation: a(b,c) = d'
        
    end
end
