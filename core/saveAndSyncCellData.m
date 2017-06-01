function [] = saveAndSyncCellData(cellData)
global CELL_DATA_FOLDER;
global CELL_DATA_MASTER;
global SERVER_ROOT;
global SYNC_TO_SERVER;
SERVER_TIME_OFFSET = 0;

save([CELL_DATA_FOLDER cellData.savedFileName '.mat'], 'cellData');

if ~SYNC_TO_SERVER
    return
end

do_sync = true;
cellDataStatusFileLocation = [SERVER_ROOT 'CellDataStatus.txt'];


% local file mod time
localFileInfo = dir([CELL_DATA_FOLDER cellData.savedFileName '.mat']);
localModDate = localFileInfo.datenum;

% Determine server mod time
if exist(CELL_DATA_MASTER, 'dir') == 7 %server is connected and CellDataMaster folder is found
    disp('CellDataMaster found');
    try
        remoteFileInfo = dir([CELL_DATA_MASTER cellData.savedFileName '.mat']);
        serverModDate = remoteFileInfo.datenum;
    catch
        serverModDate = 0;
    end
else
    disp([cellData.savedFileName ': CellDataMaster not found. Local copy being saved without sync.']);
    do_sync = false;
    serverModDate = 0;
end


fprintf('Local file is %g sec newer than server file\n',(localModDate - serverModDate) * 86400)
fileCopySlopTimeSec = 20 + SERVER_TIME_OFFSET;

if serverModDate > localModDate + fileCopySlopTimeSec/86400
    disp([cellData.savedFileName ': A newer copy of the file exists on the server. Please reload before continuing']);
    return;
end

if serverModDate + fileCopySlopTimeSec/86400 > localModDate
%     disp([cellData.savedFileName ': File is less than 120 seconds updated relative to server... waiting to sync']);
    do_sync = false;
end


if do_sync
    %syncing stuff here
    FILE_IO_TIMEOUT = 1; %s
    BUSY_STATUS_TIMEOUT = 5; %s
    
    tic;
    time_elapsed = toc;
    file_opened = false;
    while time_elapsed < FILE_IO_TIMEOUT
        fid = fopen(cellDataStatusFileLocation, 'r+');
        if fid>0
            file_opened = true;
            break;
        end
        time_elapsed = toc;
    end
    
    if ~file_opened
        disp(['Unable to open CellDataStatus.txt at' cellDataStatusFileLocation]);
        return;
    end
    
    %success in opening file
    %disp('opened file');
    M = textscan(fid, '%s%s%s%u', 'Delimiter', '\t', 'HeaderLines', 1);
    fnames = M{1};
    dates = M{2};
    usernames = M{3};
    status = M{4};
    
    %get index of current file
    ind = find(strcmp(cellData.savedFileName, fnames)==1);
    if isempty(ind) %new file to add to database
        curStatus = 0;
        ind = length(fnames)+1; %add new entry
        disp([cellData.savedFileName ': Adding new local cellData to database']);
    else %check status
        disp([cellData.savedFileName ': Found local cellData']);
        curStatus = status(ind);
    end
    
    if curStatus %file is busy
        disp('waiting for busy file');
        tic;
        time_elapsed = toc;
        fclose(fid);
        while time_elapsed < BUSY_STATUS_TIMEOUT
            fid = fopen(cellDataStatusFileLocation, 'r');
            M = textscan(fid, '%s%s%s%u', 'Delimiter', '\t', 'HeaderLines', 1);
            fnames = M{1};
            dates = M{2};
            usernames = M{3};
            status = M{4};
            
            %get index of current file
            ind = find(strcmp(cellData.savedFileName, fnames)==1);
            if isempty(ind) %new file to add to database
                curStatus = 0;
                ind = length(fnames)+1; %add new entry
                disp('adding new entry');
            else %check status
                disp([cellData.savedFileName ': Found local cellData']);
                curStatus = status(ind);
            end
            time_elapsed = toc;
            fclose(fid);
            if ~curStatus %got file
                break;
            end
        end
    end
    
    if curStatus %file is busy
        disp(['File is busy: ' cellData.savedFileName ' not updated!']);
    else
        fid = fopen(cellDataStatusFileLocation, 'w');
        %write busy flag before copying cellData
        fnames{ind} = cellData.savedFileName;
        dates{ind} = datestr(now);
        usernames{ind} = java.lang.System.getProperty('user.name').toCharArray;
        status(ind) = 1;
        
        %print file
        fprintf(fid,'%s\t%s\t%s\t%s\n','Filename', 'CheckInDate', 'CheckedInBy', 'BusyStatus');
        L = length(fnames);
        for i=1:L
            fprintf(fid,'%s\t%s\t%s\t%u\n',fnames{i}, dates{i}, usernames{i}, status(i));
        end
        fclose(fid);
        
        %do the copy
        disp([cellData.savedFileName ': Copying local file to server']);
        save([CELL_DATA_MASTER cellData.savedFileName '.mat'], 'cellData'); 
%         pause(0.5);
        %resave local version so modification date is later
%         disp([cellData.savedFileName ': Local resave']);
%         save([ANALYSIS_FOLDER 'cellData' filesep cellData.savedFileName '.mat'], 'cellData'); 
        
        %reset busy status to 0
        status(ind) = 0;
        %print file
        fid = fopen(cellDataStatusFileLocation, 'w');
        fprintf(fid,'%s\t%s\t%s\t%s\n','Filename', 'CheckInDate', 'CheckedInBy', 'BusyStatus');
        L = length(fnames);
        for i=1:L
            fprintf(fid,'%s\t%s\t%s\t%u\n',fnames{i}, dates{i}, usernames{i}, status(i));
        end
        fclose(fid);
        
    end
end

%keyboard;