function [] = importFromProject(folder_name)
    global ANALYSIS_FOLDER
    if nargin == 0
        folder_name = uigetdir([ANALYSIS_FOLDER 'Projects/'],'Choose project folder');
    end
    fid = fopen([folder_name filesep 'cellNames.txt']);
    temp = textscan(fid, '%s', 'delimiter', '\n');
    cellNames = temp{1};
    fclose(fid);
    for i = 1:length(cellNames)
        try
            insert(sl.Neuron, cellNames(i))
            fprintf('%s inserted. \n', cellNames{i})
        catch
            fprintf('error inserting %s. May be duplicate entry. \n', cellNames{i}) 
    end
end