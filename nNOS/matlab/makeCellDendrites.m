function [allPointsNew] = makeCellDendrites(startPoint, startTheta, theta_sd_vec, totalLength, Nstart_branches, branch_split_mean_vec, depth, branchInd)
allPoints = [];
allPointsNew = [];
maxDepth = 2;

if depth > maxDepth
    return;
end

Dlen = 0;
%endPoints = zeros(Nstart_branches, 2);
if depth==1
    allPoints{1}(branchInd,:) = startPoint;
end
for i=1:Nstart_branches
    if depth==1 %force uniform start branches
        curTheta(i) = rem(startTheta+360/i+randn*10, 360);
    else
        curTheta(i) = rem(360 + startTheta+randn * theta_sd_vec(depth), 360); %centered on zero
    end
    branchLen = poissrnd(branch_split_mean_vec(depth));
    [dx, dy] = pol2cart(curTheta(i)*pi/180, branchLen);
    endPoints(i,:) = [startPoint + [dx dy], branchInd, depth];
    Dlen = Dlen + branchLen;
end

if depth==1
    allPoints{2} = endPoints;
else
    allPoints{1} = endPoints;
end

%recursive calls
for i=1:Nstart_branches
    pointsNew = makeCellDendrites(endPoints(i,1:2), curTheta(i), theta_sd_vec, totalLength, Nstart_branches, branch_split_mean_vec, depth+1, i);
    if ~isempty(pointsNew)
        %if depth>1
        %    pointsNew{1}(:,3) = pointsNew{1}(:,3)+(
        %end
        allPoints = [allPoints, pointsNew];
    end
end

if depth == 1;
    N = length(allPoints);
    allPointsNew = cell(1,maxDepth+1);
    allPointsNew{1} = allPoints{1};
    
    for i=1:maxDepth
        for j=2:N
            curSet = allPoints{j};
            if curSet(1,4) == i;                
                if isempty(allPointsNew{i+1})
                    z=1;
                    %pause;
                    offset = 0;
                    allPointsNew{i+1} = curSet;                   
                else
                    z=z+1;
                    %pause;
                    if z>Nstart_branches
                        offset = offset + Nstart_branches;
                        %pause;
                        z=1;
                    end
                    curSet(:,3) = curSet(:,3)+offset;
                    allPointsNew{i+1} = [allPointsNew{i+1}; curSet];
                end
            end
        end
    end
else
    allPointsNew = allPoints;
end
