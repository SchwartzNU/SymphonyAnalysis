function addDsiOsiVarTitle(rootData, paramName)
    DSI = rootData.(sprintf('%s_DSI', paramName));
    DSang = rootData.(sprintf('%s_DSang', paramName));
    OSI = rootData.(sprintf('%s_OSI', paramName));
    OSang = rootData.(sprintf('%s_OSang', paramName));
    DVar = rootData.(sprintf('%s_DVar', paramName));

    s = sprintf('DSI: %1.2f @ %3.0f° | OSI: %1.2f @ %3.0f° | Variance: %1.2f', DSI, DSang, OSI, OSang, DVar);
    title(s);
end