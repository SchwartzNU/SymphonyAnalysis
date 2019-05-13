function [] = syncLocalRawDataToServer()
global ANALYSIS_FOLDER
global RAW_DATA_FOLDER
global RAW_DATA_MASTER

if ~(exist(RAW_DATA_MASTER, 'dir') == 7)
    disp('Could not connect to RawDataMaster');
    return;
end

disp('Sync all local raw data to server')

%get all cellData names in local cellData folder
rawDataNames = ls([RAW_DATA_FOLDER '*.h5']);
if ismac
    rawDataNames = strsplit(rawDataNames); %this will be different on windows - see doc ls
elseif ispc
    rawDataNames = cellstr(rawDataNames);
end
rawDataNames = sort(rawDataNames);

% cellDataBaseNames = cell(length(cellDataNames), 1);

for i=1:length(rawDataNames)
    [~, basename, ~] = fileparts(rawDataNames{i});
    if ~isempty(basename)
        if exist([RAW_DATA_MASTER basename '.h5'], 'file')
            continue
        else
            disp(['Copying raw data file ' basename ' to master.'])
            copyfile([RAW_DATA_FOLDER basename '.h5'], [RAW_DATA_MASTER basename '.h5']);
        end
    end
end
