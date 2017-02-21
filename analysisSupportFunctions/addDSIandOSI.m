function rootData = addDSIandOSI(rootData, angleParam)
%DSI, DSang, OSI, OSang;
angles = deg2rad(rootData.(angleParam));

fnames = fieldnames(rootData);
for i=1:length(fnames)
    curField = fnames{i};
    if isfield(rootData.(curField), 'type')
        responseMagnitudes = getRespVectors(rootData, {curField});
        
        if isempty(responseMagnitudes)
            continue
        end
        
        responseSum = sum(responseMagnitudes);
        responseVectorSumDir = sum(responseMagnitudes .* exp(sqrt(-1) * angles));
        responseVectorSumOrth = sum(responseMagnitudes .* exp(sqrt(-1) * angles * 2));

        DSI = abs(responseVectorSumDir / responseSum);
        OSI = abs(responseVectorSumOrth / responseSum);
        DSang = rad2deg(angle(responseVectorSumDir / responseSum));
        OSang = rad2deg(angle(responseVectorSumOrth / responseSum)) / 2;

        % directional variance
        DVar = var(responseMagnitudes ./ mean(responseMagnitudes));

        if DSang < 0
            DSang = 360 + DSang;
        end

        if OSang < 0
            OSang = 360 + OSang;
        end

        OSang = mod(OSang,180); %OSangles should be between [0,180]

        rootData.([curField '_DSI']) = DSI;
        rootData.([curField '_DSang']) = DSang;
        rootData.([curField '_OSI']) = OSI;
        rootData.([curField '_OSang']) = OSang;

        rootData.([curField '_DVar']) = DVar;
    end
end