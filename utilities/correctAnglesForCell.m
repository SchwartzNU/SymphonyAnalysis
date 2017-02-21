function correctAnglesForCell(cname)
    global CELL_DATA_FOLDER
    fprintf('processing cellData %s\n', cname)
    fname = fullfile(CELL_DATA_FOLDER, [cname, '.mat']);
    load(fname)
    
    
    cellData = correctAngles(cellData, cname);
    if cellData == 1
        return
    end

    %% Save cellData
    disp('saving cell data');
    save(fname, 'cellData');
    
end