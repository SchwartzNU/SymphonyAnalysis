function [] = saveDataFile_v73(fname, var, varName)
eval([varName '=var;']);
save(fname, varName, '-v7.3'); 
