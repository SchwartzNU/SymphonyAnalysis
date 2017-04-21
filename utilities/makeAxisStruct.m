function [] = makeAxisStruct(ax, igorh5path, fname, datasetName)
if nargin < 4
    datasetName = [];
end
if nargin < 3
    fname = [];
end

s = struct;
%get axis properties
Xlabel = get(ax,'Xlabel');
if ~isempty(Xlabel), s.Xlabel = get(Xlabel,'String'); end
Ylabel = get(ax,'Ylabel');
if ~isempty(Ylabel), s.Ylabel = get(Ylabel,'String'); end
s.Xlim = get(ax,'xlim');
s.Ylim = get(ax,'ylim');

%get line data and properties
plotLines = get(ax,'children');

for i=1:length(plotLines)
    curLine = plotLines(i);
    displayName = get(curLine,'DisplayName');
    if isempty(displayName), line_prefix = ['L', num2str(i)];
    else line_prefix = displayName; end
    if ~isempty(str2double(line_prefix)) %label is number
        line_prefix = ['n' line_prefix];
    end
    %replace periods in label name
    line_prefix = strrep(line_prefix,'.','pt');
    
    %replace comma in label name
    line_prefix = strrep(line_prefix,',','_');
    
    %replace minus signs in label name
    line_prefix = strrep(line_prefix,'-','m');
    
    %replace plus signs in label name
    line_prefix = strrep(line_prefix,'-','p');
    
    %replace white space in label name
    line_prefix = strrep(line_prefix,' ','_');
    
    %replace slash in label name
    line_prefix = strrep(line_prefix,'/','_');
    
    %replace bracket in label name
    line_prefix = strrep(line_prefix,'[','_');
    
    %replace bracket in label name
    line_prefix = strrep(line_prefix,']','_');
    
    %replace = in label name
    line_prefix = strrep(line_prefix,'=','eq');
    
    s.([line_prefix '_Y']) = get(curLine,'YData');
    X = get(curLine,'XData');
%     if max(diff(diff(X))) == 0 %linear X scale
%         s.([line_prefix '_start']) = X(1);
%         s.([line_prefix '_delta']) = X(2) - X(1);
%     else %separate X wave
%         s.([line_prefix '_X']) = X;
%     end
    s.([line_prefix '_X']) = X; %Otherwise doesn't export an x-axis...Adam 4/21/17
    
    if isprop(curLine,'Color')
        s.([line_prefix '_color']) = get(curLine,'Color');
    end
    s.([line_prefix '_marker']) = get(curLine,'marker');
    if isprop(curLine,'linestyle')
        s.([line_prefix '_linestyle']) = get(curLine,'linestyle');
    end
    if isprop(curLine,'markersize')
        s.([line_prefix '_markerSize']) = get(curLine,'markersize');
    end
    %error bars?
    if isprop(curLine,'UData') && ~isempty(get(curLine,'UData'))
        s.([line_prefix '_err']) = get(curLine,'UData');
    end
    %keyboard;
end

%write hdf5 file
%options.overwrite = 1;
%if isempty(fname)
%    fname = input('Figure Name: ', 's');
%end
if isempty(fname)
    [fname,pathname] = uiputfile('*.h5', 'Specify hdf5 export file for Igor', igorh5path);
else
    pathname = igorh5path;
end
if ~isempty(fname)
    if isempty(datasetName)
        datasetName = inputdlg('Enter dataset name', 'Dataset name');
    end
    if ~isempty(datasetName)
        if iscell(datasetName)
            datasetName = datasetName{1}; %inputdlg returns a cell array instead of a string
        end
        %fullfile(pathname, fname)
        exportStructToHDF5(s, fullfile(pathname, fname), datasetName);
    end
end
%exportStructToHDF5(s,[fname '.h5'],'FigData',options);
%movefile([fname '.h5'], [basedir fname '.h5']);