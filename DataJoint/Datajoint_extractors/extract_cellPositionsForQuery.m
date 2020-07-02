function positionStruct = extract_cellPositionsForQuery(q, fname)
positionStruct = struct;
f = fetch(q, 'position_x', 'position_y', 'which_eye');

N_cells = length(f);
for i=1:N_cells
    curData = f(i);
    positionStruct(i).cell_id = curData.cell_id;
    positionStruct(i).which_eye = curData.which_eye;
    positionStruct(i).position_y = curData.position_y;
    %flip x coordinate for left eye
    if strcmp(curData.which_eye, 'L')
        positionStruct(i).position_x = -curData.position_x;
    else
        positionStruct(i).position_x = curData.position_x;
    end
end

save(fname, 'N_cells', 'positionStruct');