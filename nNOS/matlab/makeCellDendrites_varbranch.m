function [allPointsNew] = makeCellDendrites_varbranch(startPoint, startTheta, theta_sd_vec, Nstart_branches, branch_split_mean_vec, depth, branchInd)
allPoints = [];
allPointsNew = [];

%maxDepth = 3;

%if depth > maxDepth
%    return;
%end

%randomly vary # of branches if desired
binomMean = mod(Nstart_branches{1},floor(Nstart_branches{1}));
if binomMean ~= 0
    Nstart_branches{1} = Nstart_branches{1} + double(rand>(1-binomMean));
end

Dlen = 0;
%endPoints = zeros(Nstart_branches, 2);
if depth==1
    allPoints{1}(branchInd,:) = startPoint;
end
for i=1:Nstart_branches{1}
    if depth==1 %force uniform start branches
        curTheta(i) = rem(startTheta+360/i+randn * theta_sd_vec(depth), 360); %startTheta == orientation
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
for i=1:Nstart_branches{1}
    if numel(Nstart_branches)==1
        pointsNew = [];
    else
        pointsNew = makeCellDendrites_varbranch(endPoints(i,1:2), curTheta(i), theta_sd_vec, Nstart_branches(2:end), branch_split_mean_vec, depth+1, i);
    end
    if ~isempty(pointsNew)
        %if depth>1
        %    pointsNew{1}(:,3) = pointsNew{1}(:,3)+(
        %end
        allPoints = [allPoints, pointsNew];
    end
end

if depth == 1;
    N = length(allPoints);
    allPointsNew = cell(1,numel(Nstart_branches)+1);
    allPointsNew{1} = allPoints{1};
    allPointsNew{2} = allPoints{2}; %only one soma to branch from
    for i=2:numel(Nstart_branches)
        %pause(1);
        for j=3:N
            curSet = allPoints{j};
            if curSet(1,4) == i; %if this point belongs in this layer
                for k=j-1:-1:2 %search through most recent sets to identify parent
                    parSet = allPoints{k};
                    if parSet(1,4) == i-1
                        %find parent in New
                        parInd = find(ismember(allPointsNew{i}(:,1:2),parSet(1,1:2),'rows'));
                        break
                    end
                end
                curSet(:,3) = curSet(:,3) + parInd - 1;
                if isempty(allPointsNew{i+1})
%                     z=1;
%                     %pause;
%                     offset = 0;
                     allPointsNew{i+1} = curSet;                   
                else
%                     z=z+1;
%                     %pause;
%                     if z>Nstart_branches{i-1} %
%                         offset = offset + Nstart_branches{i};
%                         %pause;
%                         z=1;
%                     end
%                     curSet(:,3) = curSet(:,3)+offset;
                    allPointsNew{i+1} = [allPointsNew{i+1}; curSet];
                end
                
            end
        end
    end
else
    allPointsNew = allPoints;
end
