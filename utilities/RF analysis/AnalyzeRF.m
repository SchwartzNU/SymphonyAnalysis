function [cellTypes, avgDeltaAngles] = AnalyzeRF()
load('RF_dataTable.mat')
%dataTable = dataTable(find(contains(dataTable.cellType, 'mini on', 'IgnoreCase',true)), :);


%plotEllipses(dataTable)
deltaAngles = calcDeltaAngles(dataTable.X_mirror, dataTable.Y, dataTable.Angle_mirror);
hiInd = find(dataTable.Assymetry_Amplitude >= 0.5);
% a = dataTable.cellType(hiInd,:)
%plotAngles(dataTable(hiInd,:))
plotAngles(dataTable)
plotHistogram(dataTable(hiInd,:), deltaAngles(hiInd))
[cellTypes, avgDeltaAngles, N] = cellTypeAverage(dataTable, deltaAngles);
end

function plotAngles(dataTable)
%% Find Indices of left and right eye
 lInd = find(dataTable.eye == -1);
 rInd = find(dataTable.eye == 1);

%% Plot Left Eye
figure(1)
clf
subplot(1,2,1)
hold on
anglePlotter(dataTable(lInd,:))
title('Left Eye')
xlabel('microns')
ylabel('microns')
hold off

 %% Plot Right Eye
subplot(1,2,2)
hold on
anglePlotter(dataTable(rInd,:))
title('Right Eye')
xlabel('microns')
ylabel('microns')
hold off

%% Mirror left location and angle
dataTable.X(lInd) = dataTable.X(lInd) * -1;
dataTable.Assymetry_Angle(lInd) = pi - dataTable.Assymetry_Angle(lInd);
 
 %% Plot Combined Eyes (convert left eye to right eye coordinates)
figure(2)
clf
hold on
anglePlotter(dataTable)
title('Combined')
xlabel('microns')
ylabel('microns')
hold off
end
function anglePlotter(dataTable)
%% Plot Axis and scale bar
Gain = 500;
plot([-2500;2500],[0; 0])
plot([0;0],[-2500;2500])
plot([-2300,-2300 + (Gain*.5)],[-2300,-2300],'b','LineWidth',4) %scale bar

%% Calculate X and Y components for plotting
xComponents = dataTable.Assymetry_Amplitude .* cos(dataTable.Assymetry_Angle);
yComponents = dataTable.Assymetry_Amplitude .* sin(dataTable.Assymetry_Angle);

%% Plot each cell
 for c = 1:height(dataTable)
    X(1) = dataTable.X(c) - (xComponents(c)/2 * Gain);
    X(2) = dataTable.X(c) + (xComponents(c)/2 * Gain);
    Y(1) = dataTable.Y(c) - (yComponents(c)/2 * Gain);
    Y(2) = dataTable.Y(c) + (yComponents(c)/2 * Gain);
%    text(dataTable.X(c),dataTable.Y(c),dataTable.cellName(c));
%    text(dataTable.X(c),dataTable.Y(c),dataTable.cellType(c));
    h = plot(X,Y,'k');
    set(h , 'LineWidth', 2)
 end 
end
function plotEllipses(dataTable)
%% Find Indices of left and right eye
 lInd = find(dataTable.eye == -1);
 rInd = find(dataTable.eye == 1);

%% Plot Left Eye
figure(3)
clf
subplot(1,2,1)
hold on
ellipsePlotter(dataTable(lInd,:))
title('Left Eye')
xlabel('microns')
ylabel('microns')
hold off

 %% Plot Right Eye
subplot(1,2,2)
hold on
ellipsePlotter(dataTable(rInd,:))
title('Right Eye')
xlabel('microns')
ylabel('microns')
hold off

%% Mirror left location and angle
dataTable.X(lInd) = dataTable.X(lInd) * -1;
dataTable.Assymetry_Angle(lInd) = pi - dataTable.Assymetry_Angle(lInd);
 
 %% Plot Combined Eyes (convert left eye to right eye coordinates)
figure(4)
clf
hold on
ellipsePlotter(dataTable)
title('Combined')
xlabel('microns')
ylabel('microns')
hold off
end
function ellipsePlotter(dataTable)
%% Plot Axis
plot([-2500;2500],[0; 0])
plot([0;0],[-2500;2500])

%% Plot each cell
 for c = 1:height(dataTable)
%    text(locData(c,1),locData(c,2),locCells(c));
%    text(locData(c,1),locData(c,2),cellTypes(c));
    ellipse(dataTable.Major_axis(c), dataTable.Minor_axis(c), dataTable.Assymetry_Angle(c), dataTable.X(c), dataTable.Y(c));
 end 
end
function plotHistogram(dataTable, deltaAngles)
numbins = 6;
figure(6);
histogram(deltaAngles, numbins);
xlabel('|preferred angle - polar angle|')
ylabel('Counts')

binEdges = 0:90/numbins:90;
weightedBinCounts = zeros(1,numbins);

for n = 1:numbins
    binInd = find(deltaAngles > binEdges(n) & deltaAngles <= binEdges(n+1)); 
    weightedBinCounts(n) = sum(dataTable.Assymetry_Amplitude(binInd));
end

figure(7);
histogram('BinEdges', binEdges, 'BinCounts', weightedBinCounts);
xlabel('|preferred angle - polar angle| weighted by amplitude')

figure(8)
scatter(deltaAngles, dataTable.Assymetry_Amplitude)
xlabel('|preferred angle - polar angle| weighted by amplitude')
ylabel('Assymetry Index')
end
function [cellTypes, avgDeltaAngles, N] = cellTypeAverage(dataTable, deltaAngles)
cellTypes = unique(dataTable.cellType);
avgDeltaAngles = zeros(1,length(cellTypes));
N = zeros(1,length(cellTypes));
for t = 1:length(cellTypes)
    typeInd = find(strcmp(dataTable.cellType, cellTypes(t)));
    avgDeltaAngles(t) = mean(deltaAngles(typeInd));
    N(t) = length(typeInd);
end
typeRF = table(cellTypes, avgDeltaAngles', N','VariableNames', {'CellType', 'deltaAngle', 'n'})
typeRF = sortrows(typeRF, 3,'descend')
end
