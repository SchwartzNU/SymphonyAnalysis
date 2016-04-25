function cd = correctAngles(cd, cellName)

%     if isKey(cd.attributes, 'anglesCorrected')
%         fprintf('%s angles already corrected\n', cellName);
%         cd = 1;
%         return
%     end

    % calculate rig angle offset
    if strfind(cellName,'A')
%         rig = 'A';
        rigAngle = 180;
    elseif strfind(cellName,'B')
%         rig = 'B';
        rigAngle = 270;
    end
    
    %% loop through epochs
    for ei = 1:length(cd.epochs)
        
        epoch = cd.epochs(ei);
        
        displayName = epoch.get('displayName');
        
        switch displayName
            case 'Moving Bar'
                angleName = 'barAngle';
                angleOffset = 0;
                
            case 'Drifting Gratings'
                angleName = 'gratingAngle';
                
                if epoch.get('version') < 3
                    angleOffset = 180;
                else
                    angleOffset = 0; % fixed in version 3
                end
                
            case 'Flashed Bars'
                angleName = 'barAngle';
                angleOffset = 0;
                
            case 'Drifting Texture';
                angleName = 'textureAngle';
                angleOffset = 0;
                
            case 'Bars multiple speeds'
                angleName = 'offsetAngle';
                angleOffset = 0;
            
            case 'Auto Center'
                angleName = 'rigOffsetAngle';
                angleOffset = 0;
                
            otherwise
                continue
        end
    
        % calculate displayName angle offset
        offset = angleOffset + rigAngle;
        
        % add epoch parameter to store the amount of offset made
        if isKey(epoch.attributes, 'angleOffsetForRigAndStimulus')
%             disp('already did this epoch')
            continue
        end
        epoch.attributes('angleOffsetForRigAndStimulus') = offset;
        
        % change epoch angle values (danger zone)
        origAngle = epoch.get(angleName);
        if isnan(origAngle) % for old autocenter
            origAngle = 0;
%             disp('add autocenter angle')
        end
        epoch.attributes(angleName) = mod(origAngle + offset, 360);
    end
    
    fprintf('%s angles corrected\n', cellName);
    cd.attributes('anglesCorrected') = 1;
    
end