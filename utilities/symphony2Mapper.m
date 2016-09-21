function cells = symphony2Mapper(fname)

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

    info = h5info(fname);
    epochsByCellMap = getEpochsByCellLabel(fname, info.Groups(1).Groups(2).Groups);
    numberOfCells = numel(epochsByCellMap.keys);

    cells = CellData.empty(numberOfCells, 0);
    for i = 1 : numberOfCells
        labels = epochsByCellMap.keys;
        h5epochs =  epochsByCellMap(labels{i});
        cells(i) = getCellData(fname, labels{i}, h5epochs);
    end
end

function cell = getCellData(fname, cellLabel, h5Epochs)

    cell = CellData();
    epochsTime = arrayfun(@(epoch) h5readatt(fname, epoch.Name, 'startTimeDotNetDateTimeOffsetTicks'), h5Epochs);
    [time, indices] = sort(epochsTime);
    sortedEpochTime = double(time - time(1)).* 1e-7;

    lastProtocolId = [];
    epochData = EpochData.empty(numel(h5Epochs), 0);
    [protocolId, name, protocolPath] = getProtocolId(h5Epochs(indices(1)).Name);

    for i = 1 : numel(h5Epochs)

        index = indices(i);
        epochPath = h5Epochs(index).Name;

        if ~ strcmp(protocolId, lastProtocolId)
            % start of new protocol
            parameterMap = buildAttributes(protocolPath, fname);
            parameterMap('displayName') = name;
            lastProtocolId = protocolId;
        end

        parameterMap = buildAttributes(h5Epochs(index).Groups(2), fname, parameterMap);
        parameterMap('epochNum') = i;
        parameterMap('epochStartTime') = sortedEpochTime(i);

        e = EpochData;
        e.parentCell = cell;
        e.attributes = containers.Map(parameterMap.keys, parameterMap.values);
        e.dataLinks = getResponses(h5Epochs(index).Groups(3).Groups);
        epochData(i)= e;

        [protocolId, name, protocolPath] = getProtocolId(epochPath);
    end

    cell.attributes = containers.Map();
    cell.epochs = epochData;
    cell.attributes('Nepochs') = numel(h5Epochs);
    cell.attributes('symphonyVersion') = 2.0;
    [~, file, ~] = fileparts(fname);
    cell.attributes('fname') = file;
    cell.savedFileName = [file cellLabel];
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
        
        name = getMappedDeviceName(deviceArray{1});
        path = [devicePath, '/data'];
        map(name) = path;
    end
end

function epochGroupMap = getEpochsByCellLabel(fname, epochGroups)
    epochGroupMap = containers.Map();
    
    for i = 1 : numel(epochGroups)
        h5Epochs = flattenByProtocol(epochGroups(i).Groups(1).Groups);
        label = getSourceLabel(fname, epochGroups(i));
        epochGroupMap = addToMap(epochGroupMap, label, h5Epochs);
    end

    function epochs = flattenByProtocol(protocols)
        epochs = arrayfun(@(p) p.Groups(1).Groups, protocols, 'UniformOutput', false);
        idx = find(~ cellfun(@isempty, epochs));
        epochs = cell2mat(epochs(idx));
    end
end

function label = getSourceLabel(fname, epochGroup)
    % check if it is h5 Groups
    % if not present it should be in links
    
    if numel(epochGroup.Groups) == 4
        source = epochGroup.Groups(4).Name;
    else
        source = epochGroup.Links(2).Value{:};
    end
    label = h5readatt(fname, source, 'label');
end

function map = buildAttributes(h5group, fname, map)
    if nargin < 3
        map = containers.Map();
    end
    if ischar(h5group)
        h5group = h5info(fname, h5group);
    end
    attributes = h5group.Attributes;

    for i = 1 : length(attributes)
        name = attributes(i).Name;
        root = strfind(name, '/');
        value = attributes(i).Value;

        if ~ isempty(root)
            name = attributes(i).Name(root(end) + 1 : end);
        end
        map(getMappedAttribute(name)) = value;
    end
end

function map  = addToMap(map, key, value)

    if isKey(map, key)
        map(key) = [map(key); value];
    else
        map(key) = value;
    end
end

function mappedName = getMappedDeviceName(name)
    switch name
        case 'Amp1'
            mappedName = 'Amplifier_Ch1';
        case 'Amp2'
            mappedName = 'Amplifier_Ch2';
        otherwise
            mappedName = name;
    end
end

function mappedAttr = getMappedAttribute(name)
    switch name
        case 'chan1Mode'
            mappedAttr = 'ampMode';
        case 'chan2Mode'
            mappedAttr = 'amp2Mode';
        case 'chan1Hold'
            mappedAttr = 'ampHoldSignal';
        case 'chan2Hold'
            mappedAttr = 'amp2HoldSignal';
        otherwise
            mappedAttr = name;
    end
end