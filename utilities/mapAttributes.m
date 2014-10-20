function M = mapAttributes(h5group, fname)
    M = containers.Map; 
    attributes = h5group.Attributes;
    for i=1:length(attributes)
        ind = strfind(attributes(i).Name,'/');
        if ~isempty(ind)
            name = attributes(i).Name(ind(end)+1:end);
        else
            name = attributes(i).Name;
        end
        M(name) = h5readatt(fname, h5group.Name, name);
    end
end

