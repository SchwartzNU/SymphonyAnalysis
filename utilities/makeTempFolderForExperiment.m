function [] = makeTempFolderForExperiment(expName)
    global ANALYSIS_FOLDER;
    eval(['!rm -rf ' ANALYSIS_FOLDER 'labData_temp.mat']);
    eval(['!rm -rf ' ANALYSIS_FOLDER 'cellData_temp']);
    eval(['!mkdir ' ANALYSIS_FOLDER 'cellData_temp']);
    eval(['!ln ' ANALYSIS_FOLDER 'cellData' filesep expName 'c* ' ANALYSIS_FOLDER filesep 'cellData_temp']);
end

