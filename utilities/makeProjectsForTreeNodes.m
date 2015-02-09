function [] = makeProjectsForTreeNodes(T)
global ANALYSIS_FOLDER;
folderName = inputdlg('Tree name: ', 'Enter tree name', 1, {'typologyTree'});
folderName = folderName{1};
eval(['!rm -rf ' ANALYSIS_FOLDER 'Projects' filesep folderName]);
eval(['!mkdir ' ANALYSIS_FOLDER 'Projects' filesep folderName]);

L = length(T.Node);
for i=1:L
    cellNames = T.get(i);
    eval(['!mkdir ' ANALYSIS_FOLDER 'Projects' filesep folderName filesep 'node' num2str(i)]);
    fid = fopen([ANALYSIS_FOLDER 'Projects' filesep folderName filesep 'node' num2str(i) filesep 'cellNames.txt'], 'w');
    for j=1:length(cellNames)
        if ~isempty(cellNames{j})
            fprintf(fid, '%s\n', cellNames{j});
        end
    end
    fclose(fid);
end



