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
    if isstruct(s.(fNames{i}))
        exportStructToHDF5(s.(fNames{i}), fileName, strcat(dataRoot, '/', fNames{i}));
    else
        if ~isempty(s.(fNames{i}))
            if ~strcmp(class(s.(fNames{i})), 'cfit')
                try
                    hdf5write(fileName, strcat(dataRoot, '/', fNames{i}), s.(fNames{i}), 'WriteMode', 'append');
                catch
                    disp('Did not overwrite existing dataset');
                end
            end
        end
    end
end

%
% if isfield(s_part, 'type') %special handling for nodeData structs
%             if strcmp(s_part.type, 'byEpoch')
%                 name = [fNames{i} '_mean_c'];
%                 val = s_part.mean_c;
%                 hdf5write(fileName, strcat(dataRoot, '/', name), val, 'WriteMode', 'append');
%                 name = [fNames{i} '_median_c'];
%                 val = s_part.median_c;
%                 hdf5write(fileName, strcat(dataRoot, '/', name), val, 'WriteMode', 'append');
%                 name = [fNames{i} '_SD_c'];
%                 val = s_part.SD_c;
%                 hdf5write(fileName, strcat(dataRoot, '/', name), val, 'WriteMode', 'append');
%                 name = [fNames{i} '_SEM_c'];
%                 val = s_part.SEM_c;
%                 hdf5write(fileName, strcat(dataRoot, '/', name), val, 'WriteMode', 'append');
%             elseif strcmp(s_part.type, 'singleValue')
%                 name = fNames{i};
%                 val = s_part.value;
%                 hdf5write(fileName, strcat(dataRoot, '/', name), val, 'WriteMode', 'append');
%             end

