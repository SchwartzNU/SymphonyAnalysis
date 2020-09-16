function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_test', 'sl_test');
end
obj = schemaObject;
end
