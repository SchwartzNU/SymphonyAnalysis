function prefsMap = loadPrefsMap(filename)
global ANALYSIS_FOLDER

prefsMap = containers.Map;

prefsFolder = [ANALYSIS_FOLDER 'analysisParams' filesep 'ParameterPrefs' filesep];
fid = fopen([prefsFolder filename], 'r');

lineIn = fgetl(fid);
while ischar(lineIn)
    [dataSetName, remPart] = strtok(lineIn);
    remPart = strtrim(remPart);
    z=1;
    paramSets = [];
    while ~isempty(remPart)
       [paramSet, remPart] = strtok(remPart);
       if ~isempty(paramSet)           
           paramSets{z} = paramSet;
           z=z+1;
       %else
       %    break;
       end
    end
    prefsMap(dataSetName) = paramSets;
    lineIn = fgetl(fid);
end


