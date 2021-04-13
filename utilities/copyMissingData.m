function copyMissingData()
    SERVER = getenv('SERVER');
    RAW_DATA_MASTER = [getenv('SERVER_ROOT') filesep 'RawDataMaster'];

    searchFolderName = uigetdir([SERVER filesep 'Data\'],'Choose folder to search.');
    
    fprintf('Checking the contents of RAW_DATA_MASTER \n')
    rawDataMaster = dir(RAW_DATA_MASTER);
    rawDataMaster = struct2cell(rawDataMaster);
    rawDataMaster = rawDataMaster(1,3:end);
    
    searchFiles(rawDataMaster, searchFolderName);
end

function searchFiles(rawDataMaster, searchFolderName)
RAW_DATA_MASTER = [getenv('SERVER_ROOT') filesep 'RawDataMaster'];
contents = dir(searchFolderName);

    for f = 3:length(contents)
        child = [searchFolderName,filesep, contents(f).name];

        if isfolder(child)
            searchFiles(rawDataMaster, child)

        elseif isfile(child)
            if contains(contents(f).name, '.h5') || contains(contents(f).name, 'metadata.xml')
                if ~any(strcmp(contents(f).name, rawDataMaster))
                    fprintf('copying %s to RawDataMaster \n', contents(f).name)
                    copyfile(child, [RAW_DATA_MASTER filesep] )
                end
            end
        end
    end
end