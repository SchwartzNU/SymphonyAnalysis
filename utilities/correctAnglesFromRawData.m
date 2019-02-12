function correctAnglesFromRawData(projFolder)

    global CELL_DATA_FOLDER
    global RAW_DATA_FOLDER
    global ANALYSIS_FOLDER

    if nargin == 0
        projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep]);
    end

    displayNames = {'Moving Bar', 'Drifting Gratings', 'Flashed Bar', 'Drifting Texture', 'Bars multiple speeds', 'Auto Center', 'Random Motion Edge', 'Split Field'};
    angleParamNames = {'barAngle','gratingAngle','textureAngle','offsetAngle', 'angleOffsetFromRig', 'movementAngle'};



    fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
    if fid < 0
        error(['Error: cellNames.txt not found in ' projFolder]);
        return;
    end
    temp = textscan(fid, '%s', 'delimiter', '\n');
    cellNames = temp{1};
    fclose(fid);

    files = {};
    for i = 1:length(cellNames)
        cellNameParts = textscan(cellNames{i}, '%s', 'delimiter', ',');
        cellNameParts = cellNameParts{1}; %quirk of textscan
        files = [files; cellNameParts];
    end


    % load cellData names

    numFiles = length(files);

    % loop through cellData
    % angles are relative to moving bar towards direction
    for fi = 1:numFiles

        rigMode = '';
        cellName = files{fi};
        if contains(cellName, '-')
            cellName = cellName(1:end-4);
        end
        cellDataFileName = fullfile(CELL_DATA_FOLDER, [cellName, '.mat']);

        load(cellDataFileName);

        if contains(cellName, 'A')
            rigMode = 'A with original X flip';

            % check for correction
            epoch = cellData.epochs(1);
            if isKey(epoch.attributes, 'angleOffsetFromRig')
                rigAngle = epoch.attributes('angleOffsetFromRig');
                if rigAngle == 0
                    rigMode = 'A with correct projection';
                end
            end

        elseif contains(cellName, 'B')
            rigMode = 'B with original 270 rotation';
        end

        fprintf('%s: Re-extracting and correcting; detected Rig %s\n',  cellName, rigMode);
        fixCount = 0;
        fixedDisplayNames = {};

        for epochIndex = 1:length(cellData.epochs)
            epoch = cellData.epochs(epochIndex);

%             try
                displayName = epoch.get('displayName');
%             catch
%                 continue
%             end

            if ~any(strcmp(displayName, displayNames))
                continue
            end
                        
            if isKey(cellData.attributes, 'symphonyVersion')
                h5fileName = fullfile(RAW_DATA_FOLDER, [cellData.get('fname') '.h5']);
                symphonyRawMode = 2;
            else
                h5fileName = fullfile(RAW_DATA_FOLDER, [cellData.savedFileName '.h5']);
                symphonyRawMode = 1;
            end
%             h5fileName = fullfile(RAW_DATA_FOLDER, [cellData.get('fname') '.h5']);
            
            

            % navigate to the location of the data in the h5
            paramLinks = {}; % one for per-run, one for per-epoch params, gotta check both cause of Auto Center
            try
                dataLink = epoch.dataLinks('Amplifier_Ch1');
            catch
                warning('Epoch missing amp Ch1 data link');
                continue
            end
            segments = strsplit(dataLink, '/');
            
            if symphonyRawMode == 2
                segmentsReduced = horzcat(segments(1:(end-3)), 'protocolParameters'); % use -5 to get the per-run params (like barSpeed), and -3 to get per-epoch params (like barAngle)
                paramLinks{1} = strjoin(segmentsReduced, '/');

                segmentsReduced = horzcat(segments(1:(end-5)), 'protocolParameters'); % use -5 to get the per-run params (like barSpeed), and -3 to get per-epoch params (like barAngle)
                paramLinks{2} = strjoin(segmentsReduced, '/');
            else
                segmentsReduced = horzcat(segments(1:(end-3)), 'protocolParameters'); % use -5 to get the per-run params (like barSpeed), and -3 to get per-epoch params (like barAngle)
                paramLinks{1} = strjoin(segmentsReduced, '/');
            end
            
            originalAngle = nan;
            paramNameToUse = '';
            for ii = 1:length(paramLinks)
                paramStruct = h5info(h5fileName, paramLinks{ii});
                for i = 1:length(paramStruct.Attributes)
                    paramName = paramStruct.Attributes(i).Name;
                    nameMatch = strcmp(paramName, angleParamNames);
                    if any(nameMatch)
                        originalAngle = paramStruct.Attributes(i).Value;
                        paramNameToUse = paramName;
                    end
                end
            end
                       
            if ~isnan(originalAngle)

                epoch.attributes('originalAngleFromRawData') = originalAngle;

                switch rigMode
                    case 'A with correct projection'
                        % yay for on-rig correction
                        trueAngle = originalAngle;

                    case 'A with original X flip'
                        x = -cosd(originalAngle); % x = -x
                        y = sind(originalAngle); % y = y
                        trueAngle = rad2deg(atan2(y, x));

                    case 'B with original 270 rotation'
                        y = -cosd(originalAngle); % y = -x
                        x = sind(originalAngle); % x = y
                        trueAngle = rad2deg(atan2(y, x));
                end

                trueAngle = mod(trueAngle, 360);
                epoch.attributes(paramNameToUse) = trueAngle;
                fixCount = fixCount + 1;
                fixedDisplayNames = horzcat(fixedDisplayNames, displayName);

    %                 fprintf('\tCorrected %s %s %g to %g\n', displayName, paramName, originalAngle, trueAngle);
            end
        end
        fprintf('\tCorrected %g epochs: %s\n',fixCount, strjoin(unique(fixedDisplayNames), ', '));
        save(cellDataFileName, 'cellData');
    end
    disp('Done correcting angles')
    
end

