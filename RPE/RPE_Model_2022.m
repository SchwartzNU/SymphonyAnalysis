% Model of RPE cells
% How much does the input resistance change by just closing the gap
% junctions?

%% 2006 Fortier and Bagna
%%% Equation 10

% R1 = R11 * (Rj + Rn)/((Rj + Rn) - f*R11)
% simplified: R = R11 * (Rj + R)/((Rj + R) - f*R11)

%% solve algebraically
% syms R R_I R_j;
% eqn = R == RI * (R_j + R)/((R_j + R) - f*RI);
% S = solve(eqn, RI);

% RI = [R*(Rj + R)]/ [J + R + f*R]

%% known values
f = 6; % number of neighbors
Rj = linspace(1, 10000, 1000)'; % range of gap junction resistance values to be tested
R = [20, 200, 1000]; % measured input resistances tested


%%

RI_vals = nan(length(Rj), length(R)); % single cell input resistance values
CC_vals = nan(length(Rj), length(R)); % coupling coefficient values

for i = 1:length(R) % for each measured control resistance
    r = R(i);
    for j = 1:length(Rj) % for each gap junctional resistance
        rj = Rj(j);
        ri = (r*(rj+r)) / (rj + r + f*r);
        
        RI_vals(j, i) = ri;
        cc = r / (rj + r);
        CC_vals(j, i) = cc;
    end
end


figure;
subplot(2, 1, 1)
plot(Rj, RI_vals, 'LineWidth', 2)
xlabel('Rj (M Ohm)')
ylabel('Input Resistance (M Ohm)')
xlim([0 7500])
legend(cellstr(num2str(R', ' Measured R=%-d')))
subplot(2, 1, 2)
plot(Rj, CC_vals, 'LineWidth', 2)
xlabel('Rj (M Ohm)')
ylabel('CC')
xlim([0 7500])
legend(cellstr(num2str(R', ' Measured R=%-d')))

% 0.025 to 0.15 is the physiological range of coupling coefficients
Ind = CC_vals > 0.025 & CC_vals < 0.15;
RI_CC_vals = RI_vals;
RI_CC_vals(~Ind) = nan;
figure;
hold on
for x = 1:length(R)
    scatter(Rj, RI_CC_vals(:, x), 'filled')
end
xlabel('Rj (M Ohm)')
ylabel('Input R (M Ohm)')
legend(cellstr(num2str(R', 'Measured R=%-d')))

% plot in conductance
figure;
subplot(2, 1, 1)
plot(1./Rj, RI_vals, 'LineWidth', 2)
xlabel('Gj (m Seimens)')
xlim([0 0.1]); ylim([0 500]);
ylabel('Input Resistance (M Ohm)')
legend(cellstr(num2str(R', ' Measured R=%-d')))
subplot(2, 1, 2)
plot(1./Rj, CC_vals, 'LineWidth', 2)
xlabel('Gj (m Seimens)')
xlim([0 0.1])
ylabel('CC')
legend(cellstr(num2str(R', ' Measured R=%-d')))
