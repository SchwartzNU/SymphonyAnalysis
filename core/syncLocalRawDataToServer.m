function [] = syncLocalRawDataToServer()
% ANALYSIS_FOLDER = getenv('ANALYSIS_FOLDER');
RAW_DATA_FOLDER = getenv('RAW_DATA_FOLDER');
RAW_DATA_MASTER = [getenv('SERVER_ROOT') filesep 'RawDataMaster'];

if ~(exist(RAW_DATA_MASTER, 'dir') == 7)
    disp('Could not connect to RawDataMaster');
    return;
end

disp('Sync all local raw data to server')

%get all cellData names in local cellData folder
rawDataNames = ls([RAW_DATA_FOLDER filesep '*.h5']);
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
        if exist([RAW_DATA_MASTER filesep basename '.h5'], 'file')
            continue
        else
            disp(['Copying raw data file ' basename ' to master.'])
            copyfile([RAW_DATA_FOLDER filesep basename '.h5'], [RAW_DATA_MASTER filesep basename '.h5']);
        end
    end
end
