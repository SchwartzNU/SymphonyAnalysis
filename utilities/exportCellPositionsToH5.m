function [] = exportCellPositionsToH5(cellNames)
rootFolder = '/Users/gws584/analysis/igorh5/';
fname = 'allPositions.h5';

if exist([rootFolder fname], 'file')
    delete([rootFolder fname]);
end

L = length(cellNames);

posX = zeros(L,1);
posY = zeros(L,1);
whichEye = zeros(L,1);
cellTypes = cell(L,1);

for i=1:L
    curCell = cellNames{i};
    if iscell(curCell)   %in case there are multiple cells in an array
        curCell = curCell{1};
    end
    curCell = strtok(curCell,','); %in case there are multiple cells
    disp([curCell ': cell ' num2str(i) ' of ' num2str(L)]);
    cellData = loadAndSyncCellData(curCell);
    location = cellData.location;
    if isempty(location) || (location(1) == 0 && location(2) == 0)
        posX(i) = nan;
        posY(i) = nan;
        whichEye(i) = nan;
    else
        posX(i) = location(1);
        posY(i) = location(2);
        whichEye(i) = location(3);
    end
    cellTypes{i} = cellData.cellType;
end

%remove ones without position information
ind = ~isnan(posX);
posX = posX(ind);
posY = posY(ind);
whichEye = whichEye(ind);
cellTypes = cellTypes(ind);
Ncells = length(posX);
disp([num2str(Ncells) ' with position information']);

uniqueTypes = unique(cellTypes);
Ntypes = length(uniqueTypes);


for i=1:Ntypes
    curType = uniqueTypes{i};
    if strcmp(curType(1), '-') || strcmp(curType, 'bad recording') %skip these
        disp(['Skipping ' curType]);
    else
        disp(['Working on ' curType]);
        ind = strcmp(cellTypes, curType);
        curX = posX(ind);
        curY = posY(ind);
        curEye = whichEye(ind);
        %flip x coordinates on left eye
        leftEye = curEye<0;
        curX(leftEye) = -curX(leftEye);
        s = struct;
        s.posX = curX;
        s.posY = curY;
        s.whichEye = curEye;
        
        exportStructToHDF5(s, [rootFolder fname], curType);
    end
end



