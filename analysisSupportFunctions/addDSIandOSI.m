function rootData = addDSIandOSI(rootData, angleParam)
%DSI, DSang, OSI, OSang;
anglesRad = deg2rad(rootData.(angleParam));
anglesDeg = rootData.(angleParam);

fnames = fieldnames(rootData);
for i=1:length(fnames)
    curField = fnames{i};
    if isfield(rootData.(curField), 'type')
        responseMagnitudes = getRespVectors(rootData, {curField});
        
        if isempty(responseMagnitudes)
            continue
        end
        
        % Vector DSI and OSI
        responseSum = sum(responseMagnitudes);
        responseVectorSumDir = sum(responseMagnitudes .* exp(sqrt(-1) * anglesRad));
        responseVectorSumOrth = sum(responseMagnitudes .* exp(sqrt(-1) * anglesRad * 2));

        DSI = abs(responseVectorSumDir / responseSum);
        OSI = abs(responseVectorSumOrth / responseSum);
        DSang = rad2deg(angle(responseVectorSumDir / responseSum));
        OSang = rad2deg(angle(responseVectorSumOrth / responseSum)) / 2;
        
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
        
        % directional variance
        DVar = var(responseMagnitudes ./ mean(responseMagnitudes));
        rootData.([curField '_DVar']) = DVar;       
        
        % Max response vs min response:
        compare = @(a,b) (abs(a)-abs(b))./(abs(a)+abs(b));
        
        rootData.([curField '_MaxMinRatio']) = compare(max(abs(responseMagnitudes)), min(abs(responseMagnitudes)));
        
        % Highest of (respose vs opposite response)
        oppositeIndices = circshift(1:length(anglesRad), round(length(anglesRad)/2));
        [ratio, bestAngleIndex] = max(compare(responseMagnitudes, responseMagnitudes(oppositeIndices)));
        rootData.([curField '_HighestRatio']) = ratio;
        rootData.([curField '_HighestRatioAng']) = anglesDeg(bestAngleIndex);
        
        %
    end
end
