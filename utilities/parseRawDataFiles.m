function parseRawDataFiles(expDate)
global RAW_DATA_FOLDER;
global ANALYSIS_FOLDER;
rawDataDir = RAW_DATA_FOLDER;
cellDataDir = [ANALYSIS_FOLDER 'cellData' filesep];
D_raw = dir(rawDataDir);
D_cell = dir(cellDataDir);

allCellDataNames = {};
z = 1;
for i=1:length(D_cell)
    if strfind(D_cell(i).name, '.mat')
        allCellDataNames{z} = D_cell(i).name;
        z=z+1;
    end
end
for i=1:length(D_raw)
    if any(strfind(D_raw(i).name, expDate)) &&  ~any(strfind(D_raw(i).name, 'metadata'))
        curCellName = D_raw(i).name;
        curCellName = strtok(curCellName, '.');
        
        writeOK = true;
        if strmatch(curCellName, allCellDataNames)
            answer = questdlg(['Overwrite current cellData file ' curCellName '?'] , 'Overwrite warning:', 'No','Yes','Yes');
            if strcmp(answer, 'No')
                writeOK = false;
            end            
        end
        if writeOK
            tic;
            disp(['parsing file' curCellName]);
            fname = [rawDataDir curCellName '.h5'];

            if h5readatt(fname, '/', 'version') == 2
                disp('Parsing cells in Symphony 2 file')
                cells = symphony2Mapper(fname);
                arrayfun(@(cellData) save([cellDataDir cellData.savedFileName], 'cellData'), cells);
                disp(['Elapsed time: ' num2str(toc) ' seconds']);
            else
                cellData = CellData(fname);
                save([cellDataDir curCellName], 'cellData');
                disp(['Elapsed time: ' num2str(toc) ' seconds']);   
            end
        end
    end
end
