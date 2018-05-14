function cd = correctAngles(cd, cellName)

    if isKey(cd.attributes, 'anglesCorrected') & isKey(cd.attributes, 'FB_ErrorCorrection')
        fprintf('%s angles already corrected\n', cellName);
        cd = 1;
        return
    elseif isKey(cd.attributes, 'anglesCorrected') & ~isKey(cd.attributes, 'FB_ErrorCorrection')
        FlashedBarErrorFlag = 1;
    else
        FlashedBarErrorFlag = 0;
    end

    % calculate rig angle offset
    epoch = cd.epochs(1);
    if isKey(epoch.attributes, 'angleOffsetFromRig')
        rigAngle = epoch.attributes('angleOffsetFromRig');    
    else    
        if strfind(cellName,'A')
    %         rig = 'A';
            rigAngle = 180;
        elseif strfind(cellName,'B')
    %         rig = 'B';
            rigAngle = 270;
        end
    end

    
    %% loop through epochs
    for ei = 1:length(cd.epochs)

        epoch = cd.epochs(ei);
        if isempty(epoch.parentCell)
            continue
        end
        
        if FlashedBarErrorFlag
            displayName = [epoch.get('displayName') '_FB_ErrorCorrection'];
        else
            displayName = epoch.get('displayName');
        end
        
        switch displayName
            case 'Moving Bar'
                sourceAngleName = 'barAngle';
                angleOffsetForStimulus = 0;
                
            case 'Drifting Gratings'
                sourceAngleName = 'gratingAngle';
                
                if epoch.get('version') < 3
                    angleOffsetForStimulus = 180;
                else
                    angleOffsetForStimulus = 0; % fixed in version 3
                end
                
            case 'Flashed Bar'
                sourceAngleName = 'barAngle';
                angleOffsetForStimulus = 0;
                
            case 'Flashed Bar_FB_ErrorCorrection'
                sourceAngleName = 'barAngle';
                angleOffsetForStimulus = 0;
                
            case 'Drifting Texture'
                sourceAngleName = 'textureAngle';
                angleOffsetForStimulus = 0;
                
            case 'Bars multiple speeds'
                sourceAngleName = 'offsetAngle';
                angleOffsetForStimulus = 0;
            
            case 'Auto Center'
                sourceAngleName = 'rigOffsetAngle';
                angleOffsetForStimulus = 0;
                
            otherwise
                continue
        end
        destinationAngleName = sourceAngleName;

        
        
        % check if the rig included an angle for the offset
        if isKey(epoch.attributes, 'angleOffsetFromRig')
            rigAngle = epoch.attributes('angleOffsetFromRig');
            
            if isKey(epoch.attributes, 'angleOffsetForRigAndStimulus')
                if epoch.attributes('angleOffsetFromRig') ~= epoch.attributes('angleOffsetForRigAndStimulus')
                    disp('wrong correction for rig B upper, fixing now');
                    sourceAngleName = 'originalAngle';
                end
            end
        end
                
        
        % add epoch parameter to store the amount of offset made
%         if isKey(epoch.attributes, 'angleOffsetForRigAndStimulus')
% %             disp('already did this epoch')
%             continue
%         end
    
        % calculate displayName angle offset
        overallOffset = angleOffsetForStimulus + rigAngle;
        
        epoch.attributes('angleOffsetForRigAndStimulus') = overallOffset;
        
        % change epoch angle values (danger zone)
        originalAngle = epoch.get(sourceAngleName);
        if isnan(originalAngle) % for old autocenter
            originalAngle = 0;
%             disp('add autocenter angle')
        end
        epoch.attributes('originalAngle') = originalAngle;
        correctedAngle = mod(originalAngle + overallOffset, 360);
        epoch.attributes(destinationAngleName) = correctedAngle;
    end
    
    fprintf('%s angles corrected\n', cellName);
    cd.attributes('anglesCorrected') = 1;
    cd.attributes('FB_ErrorCorrection') = 1;
    
end