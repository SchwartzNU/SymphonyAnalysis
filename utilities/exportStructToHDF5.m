function exportStructToHDF5(s, fileName, dataRoot)
% Export a 1x1 struct to HDF5 file. Each field of s is written as a dataset
% of the same name.
%
% exportStructToHDF5(s, fileName, dataRoot, options)
%
% s: struct
% fielName: hdf5 filename
% dataRoot: hdf5 root to put s under.

fileExists = exist(fileName, 'file');
% 
if ~fileExists
    fid = fopen(fileName, 'w');
    fclose(fid);
end
    
fNames = fieldnames(s);

for i = 1:length(fNames)
    if ~isstruct(s.(fNames{i}))
        if ~isempty(s.(fNames{i}))
            hdf5write(fileName, strcat(dataRoot, '/', fNames{i}), s.(fNames{i}), 'WriteMode', 'append');
        end
    end
end
