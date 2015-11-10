function nodes = localLSregistration(nodes,topInputPos,botInputPos,topOutputPos,botOutputPos)
window=5; % neighborhood size for the LS registration
maxOrder=2; % maximum multinomial order in xy
% aX^2+bXY+cY^2+dX+eY+f+gZX^2+hXYZ+iZY^2+jXZ+kYZ+lZ -> at least 12 equations needed
for kk = 1:size(nodes,1)
    % fetch the band points around an xy neighborhood for each point on the arbor
    xpos = nodes(kk,1); ypos = nodes(kk,2); zpos = nodes(kk,3);
    lx = round(xpos-window); ux = round(xpos+window); ly = round(ypos-window); uy = round(ypos+window);
    thisInT = topInputPos(topInputPos(:,1)>=lx & topInputPos(:,1)<=ux & topInputPos(:,2)>=ly & topInputPos(:,2)<=uy,:);
    thisInB = botInputPos(botInputPos(:,1)>=lx & botInputPos(:,1)<=ux & botInputPos(:,2)>=ly & botInputPos(:,2)<=uy,:);
    thisIn = [thisInT; thisInB];
    thisOutT = topOutputPos(topInputPos(:,1)>=lx & topInputPos(:,1)<=ux & topInputPos(:,2)>=ly & topInputPos(:,2)<=uy,:);
    thisOutB = botOutputPos(botInputPos(:,1)>=lx & botInputPos(:,1)<=ux & botInputPos(:,2)>=ly & botInputPos(:,2)<=uy,:);
    thisOut = [thisOutT; thisOutB];
    % convert band correspondence data into local coordinates
    xShift = mean(thisIn(:,1)); yShift = mean(thisIn(:,2));
    thisIn(:,1) = thisIn(:,1)-xShift; thisOut(:,1) = thisOut(:,1)-xShift;
    thisIn(:,2) = thisIn(:,2)-yShift; thisOut(:,2) = thisOut(:,2)-yShift;
    % calculate the transformation that maps the band points to their correspondences
    quadData = [thisIn(:,1:2) ones(size(thisIn,1),1)];
    for totalOrd = 2:maxOrder; for ord = 0:totalOrd; % slightly more general - it can handle higher lateral polynomial orders
            quadData = [(thisIn(:,1).^ord).*(thisIn(:,2).^(totalOrd-ord)) quadData];
        end; end;
    quadData = [quadData kron(thisIn(:,3),ones(1,size(quadData,2))).*quadData];
    transformMat = lscov(quadData,thisOut);
    shiftedNode = [xpos-xShift ypos-yShift];
    quadData = [shiftedNode(1:2) 1];
    for totalOrd = 2:maxOrder; for ord = 0:totalOrd; % slightly more general - it can handle higher lateral polynomial orders
            quadData = [(shiftedNode(1).^ord).*(shiftedNode(2).^(totalOrd-ord)) quadData];
        end; end;
    quadData = [quadData kron(zpos,ones(1,size(quadData,2))).*quadData];
    % transform the arbor points using the calculated transform
    nodes(kk,:) = quadData*transformMat; nodes(kk,1) = nodes(kk,1) + xShift; nodes(kk,2) = nodes(kk,2) + yShift;
end

