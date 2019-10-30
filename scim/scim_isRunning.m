function version = scim_isRunning()
%SCIM_ISRUNNING Determines which, if any, version of ScanImage appears to be currently running
%% SYNTAX
%   version = scim_isRunning()
%       version: 0 if ScanImage is not running, or an number indicating either full version number or at minimum major version number of ScanImage found running

global state

if ~isempty(state) && isfield(state,'software')     
    version = state.software.version;
elseif evalin('base','exist(''hSI'',''var'');')
    hSI = evalin('base','hSI;');
    if ~isempty(hSI)
        version = 4;
    else
        version = 0;
    end    
else
    version = 0;
end

