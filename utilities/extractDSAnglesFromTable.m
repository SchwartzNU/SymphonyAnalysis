function [angles_ONDS, angles_OODS, DSI_ONDS, DSI_OODS] = extractDSAnglesFromTable(T)
Ncells = height(T);

ind_ON = 1;
ind_OO = 1;

for i=1:Ncells
    curType = T{i,'CellType'};
    curType = curType{1};
    if T{i,'Eye'} ~= 0 && (T{i,'X'} ~=0 || T{i,'Y'} ~=0) %if we know the position
        curDSI = T{i,'DSI'};
        curAng = T{i,'DSAng'};
        if T{i,'Eye'} < 0 %flip angles from left eye
            [x,y] = pol2cart(deg2rad(curAng),1);
            [theta,~] = cart2pol(-x,y);
            curAng = rad2deg(theta);
            if curAng < 0
                curAng = curAng + 360;
            end
        end
        
        if contains(curType, 'ON DS')
            if curDSI > 0
                DSI_ONDS(ind_ON) = curDSI;
                angles_ONDS(ind_ON) = curAng;
                ind_ON = ind_ON+1;
            end
        elseif contains(curType, 'ON-OFF DS')
            if curDSI > 0
                DSI_OODS(ind_OO) = curDSI;
                angles_OODS(ind_OO) = curAng;
                ind_OO = ind_OO+1;
            end
        end
    end
end