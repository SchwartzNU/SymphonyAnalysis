function cellData = loadAndSyncCellData(cellDataName)
global ANALYSIS_FOLDER;
global SYNC_TO_SERVER;
global CELL_DATA_MASTER;
global SERVER_ROOT;
cellData_local = [];
cellData = [];
do_local_to_server_copy = false;
do_server_to_local_copy = false;
do_server_to_local_update = false;
try
    fileinfo = dir([ANALYSIS_FOLDER 'cellData' filesep cellDataName '.mat']);
    localModDate = fileinfo.datenum;
    load([ANALYSIS_FOLDER 'cellData' filesep cellDataName '.mat']); %load cellData
    cellData_local = cellData;
    disp([cellDataName ': Local copy loaded']);
catch
    disp([cellDataName ': Local copy not found']);
    localModDate = 0;
end

% Check to see if the file is recently changed
% localFileAge = (localModDate - now) * 86400;
% fprintf('Loaded file was modified %g sec ago', localFileAge)
% if localFileAge < 200
%     return
% end

if SYNC_TO_SERVER
    if exist(CELL_DATA_MASTER, 'dir') == 7 %sever is connected and CellDataMaster folder is found
%         disp('CellDataMaster found');
        cellDataStatusFileLocation = [SERVER_ROOT 'CellDataStatus.txt'];
        try
            fileinfo = dir([CELL_DATA_MASTER cellDataName '.mat']);
            serverModDate = fileinfo.datenum;
            fprintf('Local file is %g sec newer than server file\n',(localModDate - serverModDate) * 86400)

            if isempty(cellData_local)
                disp([cellDataName ': Copying server version to local cellData folder.']);
                do_server_to_local_copy = true;
            elseif serverModDate > localModDate + 1.1 / 24 %server has newer version
                disp([cellDataName ': Overwriting local version with newer server version (newer by more than 1 hr).']);
                disp('A copy of old file will be placed in cellData_localCopies');
                do_server_to_local_update = true;
            end
        catch
            disp([cellDataName ' not found in CellDataMaster.']);
            if ~isempty(cellData_local)
                disp('Copying local version to server.');
                do_local_to_server_copy = true;
            end
        end
    else
        disp(['Unable to connect to ' CELL_DATA_MASTER]);
        disp([cellDataName ': Local copy being loaded without sync']);
    end
    
    if do_local_to_server_copy || do_server_to_local_copy || do_server_to_local_update
        %synching stuff here
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
            disp(['Unable to open CellDataStatus.txt at ' cellDataStatusFileLocation]);
            return;
        end
        
        %success in opening file
        %disp('opened file');
        M = textscan(fid, '%s%s%s%u', 'Delimiter', '\t', 'HeaderLines', 1);
        fnames = M{1};
        dates = M{2};
        usernames = M{3};
        status = M{4};
        
        new_entry = false;
        %get index of current file
        ind = find(strcmp(cellDataName, fnames)==1);
        if isempty(ind) %new file to add to database
            curStatus = 0;
            ind = length(fnames)+1; %add new entry
            disp('adding new entry');
            new_entry = true;
        else %check status
            disp([cellDataName ': Found local cellData']);
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
                ind = find(strcmp(cellDataName, fnames)==1);
                if isempty(ind) %new file to add to database
                    curStatus = 0;
                    ind = length(fnames)+1; %add new entry
                    disp('adding new entry');
                    new_entry = true;
                else %check status
                    disp([cellDataName ': Found local cellData']);
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
            disp(['File is busy: ' cellDataName ' not updated!']);
        else
            fid = fopen(cellDataStatusFileLocation, 'w');
            %write busy flag before operation
            if new_entry
                fnames{ind} = cellDataName;
                dates{ind} = datestr(now);
                usernames{ind} = java.lang.System.getProperty('user.name').toCharArray;
            end
            status(ind) = 1;
            
            %print file
            fprintf(fid,'%s\t%s\t%s\t%s\n','Filename', 'CheckInDate', 'CheckedInBy', 'BusyStatus');
            L = length(fnames);
            for i=1:L
                fprintf(fid,'%s\t%s\t%s\t%u\n',fnames{i}, dates{i}, usernames{i}, status(i));
            end
            fclose(fid);
            
            %do the operation
            if do_local_to_server_copy
                disp('Doing do_local_to_server_copy');
                save([CELL_DATA_MASTER cellDataName '.mat'], 'cellData');
            elseif do_server_to_local_copy
                disp('Doing do_server_to_local_copy');
                copyfile([CELL_DATA_MASTER cellDataName '.mat'], [ANALYSIS_FOLDER 'cellData' filesep cellDataName '.mat']);
            elseif do_server_to_local_update
                disp('Doing do_server_to_local_update');
                copyfile([ANALYSIS_FOLDER 'cellData' filesep cellDataName '.mat'], [ANALYSIS_FOLDER 'cellData_localCopies' filesep cellDataName '.mat']);
                copyfile([CELL_DATA_MASTER cellDataName '.mat'], [ANALYSIS_FOLDER 'cellData' filesep cellDataName '.mat']);
            end
            
            %load updated cellData
            load([ANALYSIS_FOLDER 'cellData' filesep cellDataName '.mat']); %load cellData
            
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
end
%
%do local to server copy
%             save([filesep 'Volumes' filesep 'SchwartzLab'  filesep 'CellDataMaster'  filesep cellDataName '.mat'], 'cellData');
%