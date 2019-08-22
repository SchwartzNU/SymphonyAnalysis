function CollectRFData(dataTable_name)

 global CELL_DATA_FOLDER

%% load excel sheet
excel = readtable('C:\Users\david\Google Drive\ReceptiveFieldProject\RFDataMine_sheet.xlsx');
rowInd = find(~ismissing(excel{:,9}));
excel = excel(rowInd,[1,7,8,9,10,11]);
excel = excel(2:end,:);
excel = excel(find(contains(excel{:,1}, 'A')),:); %restrict to rigA
cellNames = excel{:,1};




%% loop through cellData to collect location information
Locations = [];
Count = 1;
for fi = 1:length(cellNames)
    fprintf('processing cellData %d of %d: %s\n', fi, length(cellNames), cellNames{fi})
    fname = fullfile(CELL_DATA_FOLDER, [cellNames{fi}, '.mat']);
    load(fname)
    if any(cellData.location)
        if any(cellData.location(1:2))
            LocatedCells{Count} = char(cellData.savedFileName);
            Locations(Count,1:3) = cellData.location;
            rfData(Count,1:3) = table2array(excel(fi,2:4));
            cellTypes{Count} = char(cellData.cellType);
            Count = Count + 1;
        else
            display(['location not recorded for ' cellNames{fi}])
        end
    else
        display(['No location information found for ' cellNames{fi}]);
    end
end
Locations(:,1) = Locations(:,1) .* -1 ;%Flip X location so positive is to the right

%% Calculate assymetry angle and amplitude
rfData = cellfun(@str2num,rfData);
rotInd = find(rfData(:,2) > rfData(:,1));
rfData(rotInd, 3) = rfData(rotInd, 3) + pi/2;
rfData(:,1:2) = sort(rfData(:,1:2),2); %sort into major and minor axes
amplitude = rfData(:,2) ./ rfData(:,1) - 1;

%% Mirror Left eye X and Angle
lInd = find(Locations(:,3) == -1); %Find indices of left eye
xMirror = Locations(:,1);
xMirror(lInd) = Locations(lInd) * -1;

angleMirror = rfData(:,3);
angleMirror(lInd) = pi - rfData(lInd,3);

%% Save table of data
varNames = {'cellName','X', 'Y','eye', 'Assymetry_Amplitude','Assymetry_Angle', 'Major_axis', 'Minor_axis', 'X_mirror', 'Angle_mirror'};
dataTable = table( LocatedCells', Locations(:,1), Locations(:,2), Locations(:,3), amplitude, rfData(:,3), rfData(:,2), rfData(:,1), xMirror, angleMirror, 'VariableNames', varNames);
save('RF_dataTable.mat', 'dataTable')
end