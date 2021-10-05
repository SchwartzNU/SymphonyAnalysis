function dt = datatip_adder_3d(ax)
try
    disp('in datatip adder')
    clickedPt = get(ax,'CurrentPoint');
    VMtx = view(ax);
    point2d = VMtx * [clickedPt(1,:) 1]';
    disp(point2d(1:3)')
    
catch
    disp('datatip not added ')
end
dt = [];