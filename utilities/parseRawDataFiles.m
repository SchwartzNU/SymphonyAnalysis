function parseRawDataFiles(expDate)
RAW_DATA_FOLDER = getenv('RAW_DATA_FOLDER');
CELL_DATA_FOLDER = getenv('CELL_DATA_FOLDER');
D_raw = dir(RAW_DATA_FOLDER);
D_cell = dir(CELL_DATA_FOLDER);

allCellDataNames = {};
z = 1;
for i=1:length(D_cell)
    if strfind(D_cell(i).name, '.mat')
        allCellDataNames{z} = D_cell(i).name;
        z=z+1;
    end
end
for i= 1:length(D_raw)
    
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
            disp(['parsing file ' curCellName]);
            fname = [RAW_DATA_FOLDER filesep curCellName '.h5'];

            if h5readatt(fname, '/', 'version') == 2
                disp('Parsing cells in Symphony 2 file')
                cells = symphony2Mapper(fname);
                arrayfun(@(cellData) save([CELL_DATA_FOLDER filesep cellData.savedFileName], 'cellData'), cells);
                disp(['Elapsed time: ' num2str(toc) ' seconds']);
                return
            else
                cellData = CellData(fname);
                save([CELL_DATA_FOLDER filesep curCellName], 'cellData');
                disp(['Elapsed time: ' num2str(toc) ' seconds']);
                return
            end
        end
    end
end
error(['Could not find raw data matching ' expDate...
    '. Are you sure you moved the raw data to the correct folder?  Is your startup file pointing to the correct folder?  Any typos?'])
