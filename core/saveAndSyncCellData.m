function [] = saveAndSyncCellData(cellData)
global ANALYSIS_FOLDER;
do_sync = true;
fileinfo = dir([ANALYSIS_FOLDER 'cellData' filesep cellData.savedFileName '.mat']);
localModDate = fileinfo.datenum;
if exist([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster']) == 7 %sever is connected and CellDataMaster folder is found
    disp('CellDataMaster found');
    try
        fileinfo = dir([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster'  filesep cellData.savedFileName '.mat']);
        serverModDate = fileinfo.datenum;
    catch
        serverModDate = 0;
    end
else
    disp([cellData.savedFileName ': CellDataMaster not found. Local copy being saved without sync.']);
    do_sync = false;
end

if serverModDate > localModDate
    disp([cellData.savedFileName ': A newer copy of the file exists on the server. Please reload before continuing']);
    return;
end

save([ANALYSIS_FOLDER 'cellData' filesep cellData.savedFileName '.mat'], 'cellData');

if do_sync
    %synching stuff here
    FILE_IO_TIMEOUT = 1; %s
    BUSY_STATUS_TIMEOUT = 5; %s
    
    tic;
    time_elapsed = toc;
    file_opened = false;
    while time_elapsed < FILE_IO_TIMEOUT
        fid = fopen('/Volumes/SchwartzLab/CellDataStatus.txt', 'r+');
        if fid>0
            file_opened = true;
            break;
        end
        time_elapsed = toc;
    end
    
    if ~file_opened
        disp('Unable to open CellDataStatus.txt');
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
        disp('adding new entry');
    else %check status
        disp('found existing entry');
        curStatus = status(ind);
    end
    
    if curStatus %file is busy
        disp('waiting for busy file');
        tic;
        time_elapsed = toc;
        fclose(fid);
        while time_elapsed < BUSY_STATUS_TIMEOUT
            fid = fopen('/Volumes/SchwartzLab/CellDataStatus.txt', 'r');
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
                disp('found existing entry');
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
        fid = fopen('/Volumes/SchwartzLab/CellDataStatus.txt', 'w');
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
        save([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster'  filesep cellData.savedFileName '.mat'], 'cellData');        
        
        %reset busy status to 0
        status(ind) = 0;
        %print file
        fid = fopen('/Volumes/SchwartzLab/CellDataStatus.txt', 'w');
        fprintf(fid,'%s\t%s\t%s\t%s\n','Filename', 'CheckInDate', 'CheckedInBy', 'BusyStatus');
        L = length(fnames);
        for i=1:L
            fprintf(fid,'%s\t%s\t%s\t%u\n',fnames{i}, dates{i}, usernames{i}, status(i));
        end
        fclose(fid);
        
    end
end

%keyboard;