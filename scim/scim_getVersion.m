function [version,minorRev,beta,betaNum] = scim_getVersion
%% function [version,minorRev,beta,betaNum] = scim_getVersion
% Function returns version info for currently installed (and running) Scanimage
%
%% SYNTAX
%   [version,minorRev,beta,betaNum] = scim_getVersion    
%       version: A decimal value containing version and major revision number (e.g. 3.5)
%       minorRev: A single integer specifying minor revision number
%       beta: Logical value specifying whether this is a beta release
%       betaNum: Integer value identifying beta release (not guaranteed to be provided for every beta)
% 
%% NOTES
%   The full version is a concatenation of the version and minorRev values. For example, a version of '3.5' and minorRev of '1' implies the full version number is 3.5.1
%
%   This function only operates if ScanImage is presently running
%  
%% CREDITS
%   Created 2/7/09, by Vijay Iyer. 
%
%% ******************************************************************************************

global state

assert(~isempty(state) && isfield(state,'software'),'No valid version of ScanImage 3 is currently running');

%Warn user if more than one version is installed
scanimages = which('scanimage','-all');
if length(scanimages) > 1
    warning('More than one ScanImage version is currently located on the path. It is recommended to run ''scim_install'' to select which ScanImage to use, and which not to use.');
end

version = state.software.version;
minorRev = state.software.minorRev;
beta = state.software.beta;
betaNum = state.software.betaNum;

outStr = ['You are currently using ScanImage version ' num2str(version)];

%Add minor revision number, if needed
if ~isempty(minorRev) && minorRev > 0
    outStr = [outStr '.' num2str(minorRev)];
end

%Add beta information, if needed
if beta
    outStr = [outStr '-beta'];
    
    if ~isempty(betaNum)
        outStr = [outStr num2str(betaNum,'%02d')];
    end
end
disp(outStr);


   
