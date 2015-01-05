function rootData = addOSI(rootData, angleParam)
%OSI, OSang;
Nangles = length(rootData.(angleParam));
angles = rootData.(angleParam);

fnames = fieldnames(rootData);
for i=1:length(fnames)
    curField = fnames{i};
    if isfield(rootData.(curField), 'type')
        respVals = getRespVectors(rootData, {curField});
        
        if ~isempty(respVals)
            R=0;
            ROrtn=0;
            for j=1:Nangles
                R=R+respVals(j);
                ROrtn = ROrtn + (respVals(j)*exp(2*sqrt(-1)*angles(j)*pi/180));
            end
            
            OSI = abs(ROrtn/R);
            OSang = angle(ROrtn/R)*90/pi;
            
            if OSang < 0
                OSang = 180 + OSang;
            end
            
            rootData.([curField '_OSI']) = OSI;
            rootData.([curField '_OSang']) = OSang;
        end
    end
end