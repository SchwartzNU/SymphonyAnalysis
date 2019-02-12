function drawCenterline(center, l, color)
if nargin < 3
    color = [0 0 0];
end
line(center(1) + [-l, l]/2, center(2) * [1,1], 'LineWidth', 1.5, 'Color', color, 'HandleVisibility','off');
line(center(1) * [1,1], center(2) + [-l, l]/2, 'LineWidth', 1.5, 'Color', color, 'HandleVisibility','off');    
    