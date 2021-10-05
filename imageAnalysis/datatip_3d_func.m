function txt = datatip_3d_func(~, info)
    %disp('in func');
    x = info.Position(1);
    y = info.Position(2);
    z = info.Position(3);
    ax = get(info.Target, 'Parent');
    hold(ax, 'on');
    scatter3(x, y, z, 20, 'r', 'filled', 'Parent', ax);
    hold(ax, 'off');
    txt = '';    
end