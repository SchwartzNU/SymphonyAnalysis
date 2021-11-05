function R = morphologyParams(S)
%S is outputStruct from rgcAnalyzer

N = size(S.edges,1);
R.branchStart = [];
R.branchLen = [];
R.branchEnd = [];

%first find branches 
curBranchLen = 0;
b = 0; %branch counter
newBranch = true;
for i=1:N   
    if newBranch
        %finishing branch
        if b>0
            ind = S.edges(i,1);
            disp(['end branch at point ' num2str(ind)]);
            R.branchEnd(b,:)= [S.allXYpos(ind,:), S.allZpos(ind)];
            curBranchLen = curBranchLen + pdist2(p1, R.branchEnd(b,:));
            R.branchLen(b,1) = curBranchLen;
            R.branchRangeZ(b,1) = range(curZ);
            R.branchLenEuc(b,1) = pdist2(R.branchEnd(b,:), R.branchStart(b,:));
        end
        %if last branch, break
        if i==N
            break;
        end        
        ind = S.edges(i,2);        
        %starting branch
        disp(['starting branch at point ' num2str(ind)]);
        b=b+1;
        R.branchStart(b,:) = [S.allXYpos(ind,:), S.allZpos(ind)];      
        ind1 = S.edges(i,1);
        p1 = [S.allXYpos(ind1,:), S.allZpos(ind1)];
        
        curBranchLen = pdist2(R.branchStart(b,:),p1);
        curZ = R.branchStart(b,3);
        %getting branch angle
        try
            ind2 = S.edges(i,2);
            p2 = [S.allXYpos(ind2,:), S.allZpos(ind2)];
            V1 = diff([p1; p2])'; %vector along the new path
            indA = ind2-1;
            indB = ind2+1;
            pA = [S.allXYpos(indA,:), S.allZpos(indA)];
            pB = [S.allXYpos(indB,:), S.allZpos(indB)];
            V2 = diff([pA; p2])';
            V3 = diff([p2; pB])';
            s1 = atan2(vecnorm(cross(V1,V2)),dot(V1,V2));
            s2 = atan2(vecnorm(cross(V1,V3)),dot(V1,V3));
            s3 = atan2(vecnorm(cross(V2,V3)),dot(V2,V3));
            s1 = abs(min(s1, pi-s1));
            s2 = abs(min(s2, pi-s2));
            s3 = abs(min(s3, pi-s3));
            R.branchAngle(b,1) = max([s1, s2, s3]);
        catch
            R.branchAngle(b,1) = 0;
        end
        
    else
        ind1 = S.edges(i,1);
        ind2 = S.edges(i,2);
        p1 = [S.allXYpos(ind1,:), S.allZpos(ind1)];
        p2 = [S.allXYpos(ind2,:), S.allZpos(ind2)];
        curBranchLen = curBranchLen + pdist2(p1,p2);
        curZ = [curZ; p1(3)];
    end
    %check next edge for new branch
    if i==N-1 %last point so end branch
        newBranch = true;
    elseif S.edges(i+1,1) - S.edges(i+1,2) == 1 %within a branch
        newBranch = false;
    else
        %S.edges(i+1,:)
        %pause;
        newBranch = true;
    end
end

R.branchTortuosity = R.branchLen ./ R.branchLenEuc;
R.Nbranches = length(R.branchAngle);
R.totalLen = sum(R.branchLen);
R.arborComplexity = R.Nbranches / R.totalLen;


