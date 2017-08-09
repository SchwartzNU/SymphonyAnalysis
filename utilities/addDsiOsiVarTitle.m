function addDsiOsiVarTitle(rootData, paramName)
    DSI = rootData.(sprintf('%s_DSI', paramName));
    DSang = rootData.(sprintf('%s_DSang', paramName));
    OSI = rootData.(sprintf('%s_OSI', paramName));
    OSang = rootData.(sprintf('%s_OSang', paramName));
    DVar = rootData.(sprintf('%s_DVar', paramName));
    Ratio = rootData.(sprintf('%s_MaxMinRatio', paramName));
    Best = rootData.(sprintf('%s_HighestRatio', paramName));
    BestAngle = rootData.(sprintf('%s_HighestRatioAng', paramName));
    dat = rootData.(paramName);
    if strcmp(dat.type, 'singleValue')
        mn = mean(dat.value);
    else
        mn = mean(dat.mean);
    end

    s = sprintf('DSI: %1.2f @ %3.0f° | OSI: %1.2f @ %3.0f° | Variance: %1.2f | Ratio: %1.2f Best: %1.2f Angle: %3.0f Mean: %.2f', DSI, DSang, OSI, OSang, DVar, Ratio, Best, BestAngle, mn);
    title(s);
end