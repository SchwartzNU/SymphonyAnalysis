function goodCells = filterProjectByCellQuality(qrSet)

    infilename = [uigetdir('', 'input file location') filesep 'cellNames.txt'];
    outfolder = uigetdir('', 'output file location');
    fid = fopen(infilename);
    fline = 'temp';
    cellNames = {};
    while ~isempty(fline)
        fline = fgetl(fid);
        if isempty(fline) || (isscalar(fline) && fline < 0)
            break;
        end
        if strfind(fline,',')
            continue;
        end
        cellNames{end+1,1} = fline;
    end
    fclose(fid);

    fprintf('Checking %g cells\n', length(cellNames));

    global CELL_DATA_FOLDER;
    goodCells = {};
    for ci = 1:length(cellNames)
        infilename = [CELL_DATA_FOLDER filesep cellNames{ci} '.mat'];
        load(infilename);
        map = cellData.tags;
        if isKey(map, 'QualityRating')
            qr = str2double(map('QualityRating'));
            if any(qr == qrSet)
                fprintf('Found good cell %g %s with quality rating %g\n', length(goodCells)+1, cellNames{ci}, qr);
                goodCells{end+1,1} = cellNames{ci};
            end
        end
    end
    
    fid = fopen([outfolder filesep  'cellNames.txt'],'w');
    for i = 1:length(goodCells)
        fprintf(fid, [goodCells{i} '\n']);
    end
    fclose(fid);
    fprintf('Wrote cell names to %s\n',[outfolder filesep  'cellNames.txt']);
    
end