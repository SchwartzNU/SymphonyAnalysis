function indexVec = multiOcurrGetIdx(list,listElement)
%Generalizing matlab's 'getnameidx.m' to multiple ocurrences
%planned for a cell array of cell arrays
%Adam 1/13/15

found = 1;
vec = [];
while found
    nextIndexOccur = getnameidx(list, listElement);
    if nextIndexOccur == 0
        found = 0;
    else
        vec = [vec, nextIndexOccur];
        list{nextIndexOccur} = {};
    end;
    
end;
indexVec = vec;

end