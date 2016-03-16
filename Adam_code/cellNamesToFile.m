    fid = fopen('cellNames.txt', 'w');
    for j=1:length(curCells)
        if ~isempty(curCells{j})
            fprintf(fid, '%s\n', curCells{j});
        end
    end
    fclose(fid);