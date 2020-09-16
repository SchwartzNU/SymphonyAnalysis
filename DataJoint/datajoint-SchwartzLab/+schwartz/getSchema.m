function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'schwartz', 'schwartz');
end
obj = schemaObject;
end
