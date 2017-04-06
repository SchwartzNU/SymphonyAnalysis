function convertColorContrastsForProject(projFolder)

global CELL_DATA_FOLDER
if nargin == 0
    projFolder = uigetdir;
end


fid = fopen([projFolder filesep 'cellNames.txt'], 'r');
if fid < 0
    errordlg(['Error: cellNames.txt not found in ' projFolder]);
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

%% loop through cellData
% angles are relative to moving bar towards direction
for fi = 1:numFiles
    fprintf('processing cellData %d of %d: %s\n', fi, numFiles, files{fi})
    fname = fullfile(CELL_DATA_FOLDER, [files{fi}, '.mat']);
    load(fname)
    
    
%     cellData = correctAngles(cellData, files{fi});
    cellData = convertColorContrasts(cellData);
    if cellData == 1
        continue
    end

    %% Save cellData
%     disp('saving cell data');
%     save(fname, 'cellData');
    
end
end


function cellData = convertColorContrasts(cd)
    for ei = 1:length(cd.epochs)

        epoch = cd.epochs(ei);
        if isempty(epoch.parentCell)
            continue
        end
        
        displayName = epoch.get('displayName');
        if strcmp(displayName, 'Color Response')
            
            epoch
            
            % extract old params
            intensity1 = epoch.get('intensity1')
            intensity2 = epoch.get('intensity2')
            baseIntensity = epoch.get('baseColor');
            baseIntensity1 = baseIntensity(1)
            baseIntensity2 = baseIntensity(2)
            fixedContrast
            
            % write new params
            epoch.attributes('displayName') = 'Color Iso Response';
            epoch.attributes('fixedContrast') = 
        end
    end
    
    cellData = cd;
end

function weber = oldToWeber(old)
    weber = old + 1;
end