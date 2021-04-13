function initializeExperiment(expname, myname)
    fprintf('Initializing experiment %s\n', expname);
    
    status = checkoutCellDataForRawData(expname);
    switch status
        case -1
            warning('No server connection could be made. Only proceed if you know that the data has not been previously parsed.')
            a = input('Are you sure you want to proceed? [y/n] ', 's');
            if a ~= 'y'
                return
            else
                parseRawDataFiles(expname);
            end
            
        case 1
            warning('cellData for this experiment is already on the server. Parsing will overwrite the cellData on the server.')
            a = input('Are you sure you want to parse new cellData? [y/n] ', 's');
            if a ~= 'y'
                return
            else
                parseRawDataFiles(expname);
            end
            
        case 0
            parseRawDataFiles(expname);
    end
    
    try
        projFolder = makeTempFolderForExperiment(expname);
    catch err
        warning('no cells were parsed from the h5 data');
        rethrow(err)
    end

    addRecordedByToProject(projFolder, myname);
%     correctAnglesForProject(projFolder);
    correctAnglesFromRawData(projFolder);
    
    LabDataGUI(projFolder);
    
    disp('Done with init');
end