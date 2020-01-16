function initializeExperiment(expname, myname)
    fprintf('Initializing experiment %s\n', expname);
    
    status = checkoutCellDataForRawData(expname);
    switch status
        case -1
            a = input(['No server connection could be made. Only proceed if you',...
                '\nknow that the data has not been previously parsed.',...
                '\nAre you sure you want to proceed? [y/n] '], 's')
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
        rethrow(e)
    end

    addRecordedByToProject(projFolder, myname);
%     correctAnglesForProject(projFolder);
    correctAnglesFromRawData(projFolder);
    
    LabDataGUI(projFolder);
    
    disp('Done with init');
end