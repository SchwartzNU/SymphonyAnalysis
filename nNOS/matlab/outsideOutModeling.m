Cm = 1e-6; % biophysical constant in F/cm^2

%results:
% -500pA current, 0pA hold
% C = 12.7 pF
% SA_um = 1269 um^2
% Rm = 904.2 Ohm*cm^2
%
% -500pA current, 100pA hold
% C = 15.6 pF
% SA_um = 1558 um^2
% Rm = 1087.9 Ohm*cm^2
%
% -100 and -20 pA are similar

%eval
R = dV/dI; %total resistance in Ohms
C = tau/R; %total capacitance in Farads

SA = C / Cm ; % surface area in cm^2
SA_um = SA * 1e8; % surface area in um^2
Rm = R * SA ; %membrane resistivity in Ohms*cm^2


% data fit from cftool
% -500 pA current, 0pA hold
dI=500e-12; %current in Amps
dV=35.62e-3; %voltage in Volts
tau=1/1106; %time in seconds

% -500 pA current, 100pA hold
dI=600e-12; %current in Amps
dV=41.9e-3; %voltage in Volts
tau=1/919.2; %time in seconds

% -20 pA current, 0pA hold
dI=20e-12; %current in Amps
dV=1.498e-3; %voltage in Volts
tau=1/876.2; %time in seconds

% -100 pA current, 0pA hold
dI=100e-12; %current in Amps
dV=7.41e-3; %voltage in Volts
tau=1/1158; %time in seconds


