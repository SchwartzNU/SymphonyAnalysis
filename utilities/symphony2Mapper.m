function cell = symphony2Mapper(fname)

    % experiement (1)
    %   |__devices (1)
    %   |__epochGroups (2)
    %       |_epochGroup-uuid
    %           |_epochBlocks (1)
    %               |_<protocol_class>-uuid (1) #protocols
    %                   |_epochs (1)
    %                   |   |_epoch-uuid (1)    #h5EpochLinks
    %                   |      |_background (1)
    %                   |      |_protocolParameters (2)
    %                   |      |_responses (3)
    %                   |        |_<device>-uuid (1)
    %                   |            |_data (1)
    %                   |_protocolParameters(2)

    cell = CellData();
    info = h5info(fname);
    
    h5Epochs = flattenEpochs(info.Groups(1).Groups(2).Groups);
    
    epochsTime = arrayfun(@(epoch) h5readatt(fname, epoch.Name, 'startTimeDotNetDateTimeOffsetTicks'), h5Epochs);
    [time, indices] = sort(epochsTime);
    sortedEpochTime = double(time - time(1)).* 1e-7;

    lastProtocolId = [];
    epochData = EpochData.empty(numel(h5Epochs), 0);
    [protocolId, name, protocolPath] = getProtocolId(h5Epochs(1).Name);

    for i = 1 : numel(h5Epochs)

        index = indices(i);
        epochPath = h5Epochs(index).Name;

        if ~ strcmp(protocolId, lastProtocolId)
            % start of new protocol
            parameterMap = mapAttributes(protocolPath, fname);
            parameterMap('displayName') = name;
            lastProtocolId = protocolId;
        end

        parameterMap = mapAttributes(h5Epochs(index).Groups(2), fname, parameterMap);
        parameterMap('epochNum') = i;
        parameterMap('epochStartTime') = sortedEpochTime(i);

        e = EpochData;
        e.parentCell = cell;
        e.attributes = parameterMap;
        e.dataLinks = getResponses(h5Epochs(index).Groups(3).Groups);
        epochData(i)= e;

        [protocolId, name, protocolPath] = getProtocolId(epochPath);
    end

    cell.attributes = containers.Map();
    cell.epochs = epochData;
    cell.attributes('Nepochs') = numel(h5Epochs);
    [~, cell.savedFileName, ~] = fileparts(fname);

end

function [id, name, path] = getProtocolId(epochPath)

    indices = strfind(epochPath, '/');
    id = epochPath(indices(end-2) + 1 : indices(end-1) - 1);
    path = [epochPath(1 : indices(end-1) - 1) '/protocolParameters'] ;
    nameArray = strsplit(id, '-');
    name = nameArray{1};
end

function map = getResponses(responseGroups)
    map = containers.Map();
    
    for i = 1 : numel(responseGroups)
        
        devicePath = responseGroups(i).Name;
        indices = strfind(devicePath, '/');
        id = devicePath(indices(end) + 1 : end);
        deviceArray = strsplit(id, '-');
        
        name = deviceArray{1};
        path = [devicePath, '/data'];
        map(name) = path;
    end
end

function h5Epochs = flattenEpochs(epochGroups)
    h5Epochs = [];

    for i = 1 : numel(epochGroups)
        h5Epochs = [h5Epochs; flattenByProtocol(epochGroups(i).Groups(1).Groups)];
    end

    function epochs = flattenByProtocol(protocols)
        epochs = arrayfun(@(p) p.Groups(1).Groups, protocols, 'UniformOutput', false);
        epochs = cell2mat(epochs);
    end
end

