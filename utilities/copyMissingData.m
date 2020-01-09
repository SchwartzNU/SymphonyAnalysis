function copyMissingData()
    global SERVER;
    global RAW_DATA_MASTER;

    searchFolderName = uigetdir([SERVER, 'Data\'],'Choose folder to search.');
    
    fprintf('Checking the contents of RAW_DATA_MASTER \n')
    rawDataMaster = dir(RAW_DATA_MASTER);
    rawDataMaster = struct2cell(rawDataMaster);
    rawDataMaster = rawDataMaster(1,3:end);
    
    searchFiles(rawDataMaster, searchFolderName);
end

function searchFiles(rawDataMaster, searchFolderName)
global RAW_DATA_MASTER;
global SERVER;
contents = dir(searchFolderName);

    for f = 3:length(contents)
        child = [searchFolderName,filesep, contents(f).name];

        if isfolder(child)
            searchFiles(rawDataMaster, child)

        elseif isfile(child)
            if contains(contents(f).name, '.h5') || contains(contents(f).name, 'metadata.xml')
                if ~any(strcmp(contents(f).name, rawDataMaster))
                    fprintf('copying %s to RawDataMaster \n', contents(f).name)
                    copyfile(child, RAW_DATA_MASTER)
                end
            end
        end
    end
end