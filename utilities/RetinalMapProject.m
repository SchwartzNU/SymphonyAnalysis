function RetinalMapProject(projFolder)

global CELL_DATA_FOLDER
global ANALYSIS_FOLDER

if nargin == 0
    projFolder = uigetdir([ANALYSIS_FOLDER 'Projects' filesep]);
end

fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
if fid < 0
    error(['Error: cellNames.txt not found in ' projFolder]);
    return;
end
temp = textscan(fid, '%s', 'delimiter', '\n');
cellNames = temp{1};
fclose(fid);

files = {};
for i = 1:length(cellNames)
    cellNameParts = textscan(cellNames{i}, '%s', 'delimiter', ',');
    cellNameParts = cellNameParts{1}; %quirk of textscan
    files = [files; cellNameParts];
end

%% load cellData names

numFiles = length(files);

%% loop through cellData to collect location information
Location = [];
Count = 1
for fi = 1:numFiles
    fprintf('processing cellData %d of %d: %s\n', fi, numFiles, files{fi})
    fname = fullfile(CELL_DATA_FOLDER, [files{fi}, '.mat']);
    load(fname)
    if any(cellData.location)
        if any(cellData.location(1:2))
            LocatedCells{Count} = char(cellData.savedFileName);
            Location(Count,1:3) = cellData.location;
            Count = Count + 1;
        else
            display(['location not recorded for ' files{fi}])
        end
    else
        display(['No location information found for ' files{fi}]);
    end
end

%% Correct X values and sort Left and Right Eyes
Location(:,1) = Location(:,1) .* -1 %correct X location
 
 LeftEye = Location(find(Location(:,3) == -1),:);
 RightEye = Location(find(Location(:,3) == 1),:);
 LeftCells = LocatedCells(find(Location(:,3) == -1));
 RightCells = LocatedCells(find(Location(:,3) == 1));
 
Location(:,1) = Location(:,1).*Location(:,3);

%% Collect OSI and OSAng information from Analysis Tree
 %[OSICells, OSI, OSAng] = CollectOSI;
%  [SupCells, Sup] = CollectSuppression('SpotsMultiSizeAnalysis')
 
%% Plot Left Eye
figure
LocData = LeftEye;
LocCells = LeftCells;

subplot(1,2,1)
scatter(LeftEye(:,1), LeftEye(:,2))
%OSIPlotter(OSICells, LocData, LocCells, OSI, OSAng)
%SMSPlotter(SupCells, LocData, LocCells, Sup)
%keyboard;
title('Left Eye')

 %% Plot Right Eye
LocData = RightEye
LocCells = RightCells

subplot(1,2,2)
scatter(RightEye(:,1), RightEye(:,2))
%OSIPlotter(OSICells, LocData, LocCells, OSI, OSAng)
%SMSPlotter(SupCells, LocData, LocCells, Sup)
%colorbar
title('Right Eye')

 
 %% Plot Combined Eyes (convert left eye to right eye coordinates)
figure
hold on
LocData = Location
scatter(Location(:,1), Location(:,2))
%LocCells = LocatedCells
%OSIPlotter(OSICells, LocData, LocCells, OSI, OSAng)
% SMSPlotter(SupCells, LocData, LocCells, Sup)
%colorbar
title('Combined')
keyboard;
end
