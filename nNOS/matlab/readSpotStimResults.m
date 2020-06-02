function [stimNames, maxDepol, maxDiff, allV_D, allV_L] = readSpotStimResults(rootDir)
D = dir(rootDir);
stimNames = [];
maxDepol = [];
maxDiff = [];
allV_D = [];
allV_L = [];

z=1;
for i=1:length(D)
    curName = D(i).name;
    if strfind(curName, 'Vmax');
        %curName                      
        if strfind(curName, 'dark');
            stimNames{z} = strtok(curName, '_Vmax');
            lightName = strrep(curName,'dark','light');            
            Vmax_D = dlmread([rootDir filesep curName]);
            Vmax_D_flat = reshape(Vmax_D, [numel(Vmax_D), 1]); 
            allV_D = [allV_D, Vmax_D_flat];
            Vmax_L = dlmread([rootDir filesep lightName]);
            Vmax_L_flat = reshape(Vmax_L, [numel(Vmax_L), 1]);
            allV_L = [allV_L, Vmax_L_flat];
            
            maxDepol(z) = max(Vmax_L_flat);
            maxDiff(z) = max(Vmax_L_flat - Vmax_D_flat);
            
            z=z+1;
        end
        
    end
end

