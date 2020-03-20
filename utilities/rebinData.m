function [rebinnedData,binIdx] = rebinData(data,sizeVec,sizeBins,timeVec,timeRange)
tol=1e-3;
delta = 100; %this is terrible, no good, god awful

timeMinErr = cellfun(@(x) min(abs(x-timeRange(1))),timeVec,'uniformoutput',false);
timeMaxErr = cellfun(@(x) min(abs(x-timeRange(2))),timeVec,'uniformoutput',false);

timeMinIdx = cellfun(@(x,y) find(abs(x-timeRange(1))==y),timeVec,timeMinErr,'uniformoutput',false);
timeMaxIdx = cellfun(@(x,y) find(abs(x-timeRange(2))==y),timeVec,timeMaxErr,'uniformoutput',false); %this is just the other plus some constant
binIdx = cellfun(@(x) nthfind(abs(bsxfun(@minus,x,sizeBins'))==min(abs(bsxfun(@minus,x,sizeBins')),[],2)),sizeVec,'uniformoutput',false);

rebinnedData = cellfun(@subsassgnif,data,binIdx,timeMinIdx,timeMaxIdx,'uniformoutput',false);

[timeMinErr{cellfun(@isempty,timeMinErr)}]=deal(0);
[timeMaxErr{cellfun(@isempty,timeMaxErr)}]=deal(0);

tne = cell2mat(timeMinErr)>tol;
txe = cell2mat(timeMaxErr)>tol;
temp=[];
rebinnedData(tne) = cellfun(@padleft,rebinnedData(tne),timeMinErr(tne),'uniformoutput',false);
rebinnedData(txe) = cellfun(@padright,rebinnedData(txe),timeMaxErr(txe),'uniformoutput',false);

%if time points are missing, then rebinnedData will not be uniform
%we will just pad the edges of the data in time

    function a=padleft(x,y)
        if isempty(x) || isempty(y)
            a=[];
            return
        end
        a=cat(2,repmat(x(:,1),1,y*delta),x);
    end
    function a=padright(x,y)
        if isempty(x) || isempty(y)
            a=[];
            return
        end
        a=cat(2,x,repmat(x(:,end),1,y*delta));
    end
end

function c = nthfind(inMat)
%just finds columns for unique rows
[r,c] = find(inMat);
c = c(logical(diff([0;r])));

end



function a = subsassgnif(x,y,z,w)
if isempty(x) || isempty(y) || isempty(z) || isempty(w)
    a=[];
    return
end
a = x(y,z:w);
end