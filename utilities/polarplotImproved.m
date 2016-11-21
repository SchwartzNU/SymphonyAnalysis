function h = polarplotImproved(angles_deg, values)

angles_deg(end+1) = angles_deg(1);
values(end+1) = values(1);

h = polarplot(deg2rad(angles_deg), values);