function scim_upgrade(newVersion,oldVersion)
%SCIM_UPGRADE Utility function for upgrading data files (e.g. INI, CFG,
%USR) to work with newer version of ScanImage. Function upgrades all files
%of specified file extension in the the selected directory(s), and then
%saves all upgraded files to a common target directory

%Shared variables
versionMap = containers.Map;
versionMap('3.0') = '3.0';
versionMap('3.5') = '3.5.x';
versionMap('3.5.1') = '3.5.x';
versionMap('3.5.x') = '3.5.x';
versionMap('3.6') = '3.6.x';
versionMap('3.6.1') = '3.6.x';
versionMap('3.6.x') = '3.6.x';
versionMap('3.7') = '3.7.x';
versionMap('3.7.1') = '3.7.x';
versionMap('3.7.x') = '3.7.x';
versionMap('3.8') = '3.8.x';
versionMap('3.8.x') = '3.8.x';


switch versionMap(newVersion)
    case '3.8.x'
        upgradeTo38X(oldVersion);
    otherwise
        error('Upgrade to version ''%s'' not supported at this time',versionMap(newVersion));
end

    function upgradeTo38X(oldVersion)
        assert(strcmpi(versionMap(oldVersion),'3.7.x'),'Can only auto-upgrade data files to version 3.8.x from version 3.7.x at this time');
        
        %Select source file path
        sourcePath = uigetdir(most.idioms.startPath,sprintf('Select source data file path (r%s)',oldVersion));
        if isnumeric(sourcePath)
            return;
        end
        
        %Select target file path
        targetPath = uigetdir(fileparts(sourcePath),sprintf('Select target data file path (r%s)',newVersion));
        if ~isnumeric(targetPath)
            %Shared vars
            s.defaultScanAngleReference = 15;
            s.sourcePath = sourcePath;
            s.targetPath = targetPath;
            
            modifyFiles(targetPath,sourcePath,getFilesOfType(sourcePath,'.ini'),@(str,fname)upgradeTo38X_ini(str,fname,s));
            modifyFiles(targetPath,sourcePath,getFilesOfType(sourcePath,'.cfg'),@(str,fname)upgradeTo38X_cfg(str,fname,s));
            modifyFiles(targetPath,sourcePath,getFilesOfType(sourcePath,'.usr'),@(str,fname)upgradeTo38X_usr(str,fname,s));
        end
    end

end

%% UPGRADE-SPECIFIC FUNCTIONS

function str = upgradeTo38X_ini(str,fileName,shared)

%MOD: Add scanAngularRangeReference vars
str = strrep(str,'structure init',...
    sprintf(['structure init\n' ...
    '%%ADDED BY UPGRADE\n' ...
    '%% Scan angular range, specified in optical degrees\n' ...
    'scanAngularRangeReferenceFast=%d\n' ...
    'scanAngularRangeReferenceSlow=%d\n' ...
    '\n'], shared.defaultScanAngleReference, shared.defaultScanAngleReference));

%MOD - Remove defunct GUI binding
str = strrep(str,'Gui gh.configurationGUI.xScanOffset',''); %Remove defunct GUI binding
str = strrep(str,'Gui gh.configurationGUI.yScanOffset',''); %Remove defunct GUI binding

%MOD - Comment out defunct state vars
defunctVars = {'externalStartTrigTerminals' 'nextTrigTerminals' 'posnResolution'};

for j=1:length(defunctVars)
    %strrep(str,defunctVars{j},sprintf('%%UPGRADE NOTE: Var ''%s'' unused in ScanImage 3.8, so it has been commented out\n%%%s',defunctVars{j},defunctVars{j}));
    str = strrep(str,sprintf('%s=',defunctVars{j}),['%REMOVED BY UPGRADE ' defunctVars{j} '=']);
end

%MOD - Uncommenting of all Pockels vars
pockelsGenVars = {'beamName' 'pockelsVoltageRange' 'photodiodeInputNegative' ...
                    'powerConversion' 'rejected_light' 'maxPower' 'maxLimit' 'photodiodeOffset'};
                           
pockelsBoardVars = {'pockelsBoardID' 'photodiodeInputBoardID'};
pockelsChanVars = {'pockelsChannelIndex' 'photodiodeInputChannel'};
pockelsIDVars = [pockelsBoardVars pockelsChanVars];
                
for i=1:3 %Up to 3 beams
   for j=1:length(pockelsGenVars)
       v = pockelsGenVars{j};       
       str = regexprep(str,['(?<comment>%)(?<lhs>\s*' v num2str(i) '=)'],'$<lhs>');              
   end      
   
   for j=1:length(pockelsIDVars)
       matchStr = ['(?<comment>%*)(?<lhs>\s*' pockelsIDVars{j} num2str(i) '=)(?<rhs>\S*)'];
       s = regexpi(str,matchStr,'names','once');
       
       if ~isempty(s)
           if ~isempty(s.comment) 
               if ismember(pockelsIDVars{j},pockelsBoardVars)
                   s.rhs = '''''';
               elseif ismember(pockelsIDVars{j},pockelsChanVars)
                   s.rhs = '[]';
               else
                   assert(false);
               end
           end
           
           str = regexprep(str,matchStr,['$<lhs>' s.rhs]);
       end
   end

end


end

function str = upgradeTo38X_cfg(str,fileName,shared)

%MOD - scanAngularRangeFast/Slow --> scanAngleMultiplerFastSlow
vars = {'scanAngularRangeFast' 'scanAngularRangeSlow'};
for j=1:length(vars)
    regExpStr = [vars{j} '=(?<val>\S*)'];
    tokens = regexp(str,regExpStr,'names');
    assert(length(tokens) <= 1);
    
    if length(tokens)
        newVal = str2double(tokens.val) / shared.defaultScanAngleReference;
        str = regexprep(str,regExpStr,['scanAngularRangeFast=' num2str(newVal)]);
    end
end


%MOD: UserFcnFindings --> UserFcnBindingsCFG
for j=1:10
    str = strrep(str,sprintf('userFcnBindings%d=',j),sprintf('userFcnBindingsCFG%d=',j));
end

% %MOD: msPerLine menu encoding shift
% regExpStr = 'msPerLineGUI=(?<val>\S*)';
% tokens = regexp(str,regExpStr,'names');
% assert(length(tokens) <= 1);
% if length(tokens)
%     newVal = str2double(tokens.val) + 2;
%     str = regexprep(str,regExpStr,['msPerLineGUI=' num2str(newVal)]);
% end

%MOD: Fill Fraction menu encoding shift
regExpStr = 'fillFractionGUIArray=(?<val>[^\n\r]+)';
tokens = regexp(str,regExpStr,'names');
assert(length(tokens) <= 1);
if length(tokens)
    oldVal = str2double(tokens.val);
    if isnan(oldVal)
        oldVal = str2num(tokens.val(2:end-1)); %#ok<ST2NM> %Remove start/end quotes
        newVal = oldVal + 4;
        str = regexprep(str,regExpStr,['fillFractionGUIArray=''[' num2str(newVal) ']''']);
    else
        newVal = oldVal + 4;
        str = regexprep(str,regExpStr,['fillFractionGUIArray=' num2str(newVal)]);
    end
end


%MOD: channels menu encoding shift
warnUpgrade = false;
for j=1:4
    regExpStr = ['voltageRangeGUI' num2str(j) '=(?<val>\S*)'];
    tokens = regexp(str,regExpStr,'names');
    assert(length(tokens) <= 1);
    
    if length(tokens)
        oldVal = str2double(tokens.val);
        
        if oldVal <= 4
            newVal = oldVal + 2;
            str = regexprep(str,regExpStr,['voltageRangeGUI' num2str(j) '=' num2str(newVal)]);
        else 
            %TODO: Support case of ranges other than 1,2,5,10V -- dealing with just mapping from 3.7.1->3.8, since 3.7 failed to save inputVoltageRangeX to CFG file nayway
            warnUpgrade = true;
        end
    end
end
if warnUpgrade
    warning(warnSI3CfgUpgrade('voltageRangeGUI<1-4>',fileName));
end

%MOD: standardMode-->acq
str = strrep(str,'structure standardMode','structure acq');

%MOD: zStepPerSlice-->zStepSize
str = strrep(str,'zStepPerSlice','zStepSize');

%MOD: averaging-->numAvgFramesSave
averagingToken = regexp(str,'averaging=(?<val>[^\n\r]*)','names');
numFramesToken = regexp(str,'numberOfFrames=(?<val>[^\n\r]*)','names');

if ~isempty(averagingToken)
    averagingVal = str2double(averagingToken.val);
    
    if averagingVal
       if ~isempty(numFramesToken)           
           regexprep(str,'averaging=[^\n\r]*',['numAvgFramesSave=' numFramesToken.val]);           
       else
           regexprep(str,'averaging=[^\n\r]*','numAvgFramesSave=1');
           warning(warnSI3CfgUpgrade('averaging',fileName));
       end        
    end
end

end

function str = upgradeTo38X_usr(str,fileName,shared)

%MOD: GUI renamings
oldNames = {'imageGUI' 'configurationGUI' 'motorGUI'};
newNames = {'imageControls' 'configurationControls' 'motorControls'};

for i=1:length(oldNames)
    str = strrep(str,oldNames{i},newNames{i});
end

%MOD: scanXXXReset --> scanXXXBase
str = strrep(str,'Reset','Base');

%MOD: Remove framesPerFileGUI, if found (was in USR file in 3.7 -- no longer in either 3.7.1 or 3.8)
str = strrep(str,'framesPerFileGUI','%framesPerFileGUI');

%MOD: state.standardMode.configName/Path-->state.configName/Path
str = regexprep(str,'structure standardMode(?<configInfo>.*?)endstructure','\n$<configInfo>\n');

%MOD: change sourcePath->targetPath
cfgVarNames = {'configPath' 'fastConfig1' 'fastConfig2' 'fastConfig3' 'fastConfig4' 'fastConfig5' 'fastConfig6' 'lastFastConfigPath'}; 

warnUpgrade = false;
for i=1:length(cfgVarNames)
    %     regExpStr = 'configPath=(<sourceCfgPath>[^\n\r]*';
    %     tokens = regexp(str,regExpStr,'names');
    %     if strfind(lower(tokens.sourceCfgPath),lower(shared.sourcePath))
    %         newCfgPath = strrep(lower(tokens.sourceCfgPath),lower(shared.sourcePath),lower(shared.targetPath));
    %         str = regexprep(str,regExpStr,sprintf('configPath=''%s''',newCfgPath);
    %     else
    %         warning(warnSI3CfgUpgrade('configPath',fileName));
    %     end
    
    
    regExpStr = [cfgVarNames{i} '=(?<sourceCfgPath>[^\n\r]*)'];
    tokens = regexp(str,regExpStr,'names');
    
    assert(length(tokens) <= 1);
    if length(tokens)
        if strfind(lower(tokens.sourceCfgPath),lower(shared.sourcePath))
            newCfgPath = strrep(lower(tokens.sourceCfgPath),lower(shared.sourcePath),lower(shared.targetPath));
            newCfgPath = strrep(newCfgPath,'\','\\');
            str = regexprep(str,regExpStr,[cfgVarNames{i} '=' newCfgPath]); 
        elseif ~isempty(eval(tokens.sourceCfgPath)) %A path is specified, but does not contain the source path motif
            warnUpgrade = true;
        end
    end
end

if warnUpgrade
    warning(warnSI3CfgUpgrade('configPath, fastConfig<1-6>, and/or lastFastConfigPath',fileName));
end   

end

%% UTILITY FUNCTIONS
function modifyFiles(targetPath,sourcePath,sourceFileNames,modifyFcn)

for i=1:length(sourceFileNames)
    fileName = sourceFileNames{i};
    
    %Read input file contents into a long string var
    inFid =  fopen(fullfile(sourcePath,fileName),'r');
    
    str = '';
    while ~feof(inFid)
        str = [str fgets(inFid)]; %#ok<AGROW>
    end
    fclose(inFid);
    
    %Modify file string
    str = feval(modifyFcn,str,fileName);
    
    %Write to target fiel
    outFid = fopen(fullfile(targetPath,fileName),'w');
    fprintf(outFid,'%s',str);
    fclose(outFid);
end

end

function warnMsg = warnSI3CfgUpgrade(varName,fileName)
warnMsg = sprintf('File ''%s'' is not fully upgraded. Please check/update the variable ''%s'', either directly in the file or by loading, reconfiguring, and resaving the CFG file within ScanImage operation.',fileName,varName);
end

function fileNames = getFilesOfType(dirName,fileExt)

listing = dir(dirName);
listing([listing.isdir]) = [];

fileNames = {listing.name};
matchExtIndices = cellfun(@(f)strcmpi(getFileExtension(f),fileExt),fileNames);

fileNames = fileNames(matchExtIndices);

end

function ext = getFileExtension(fileName)
[~,~,ext] = fileparts(fileName);
end


