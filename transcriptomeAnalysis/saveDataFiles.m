function [] = saveDataFiles(fname, varargin)
L = length(varargin);
if rem(L,2) ~= 0
    disp('Error: must specify variables in pairs');
    return;
end
N = L/2;

for i=1:N
    var = varargin{(i-1)*2+1};
    varName = varargin{(i-1)*2+2};
    eval([varName '=var;']);
    if i==1
        save(fname, varName);
    else
        save(fname, varName, '-append'); 
    end
end