function rootData = addDSIandOSI(rootData, angleParam)
%DSI, DSang, OSI, OSang;
Nangles = length(rootData.(angleParam));
angles = rootData.(angleParam);

fnames = fieldnames(rootData);
for i=1:length(fnames)
    curField = fnames{i};
    if isfield(rootData.(curField), 'type')
        respVals = getRespVectors(rootData, {curField});
        
        if ~isempty(respVals)
            R=0;
            RDirn=0;
            ROrtn=0;
            for j=1:Nangles
                R=R+respVals(j);
                RDirn = RDirn + (respVals(j)*exp(sqrt(-1)*angles(j)*pi/180));
                ROrtn = ROrtn + (respVals(j)*exp(2*sqrt(-1)*angles(j)*pi/180));
            end
            
            DSI = abs(RDirn/R);
            OSI = abs(ROrtn/R);
            DSang = angle(RDirn/R)*180/pi;
            OSang = angle(ROrtn/R)*90/pi;
            
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
        end
    end
end