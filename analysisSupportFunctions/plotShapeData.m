function [] = plotShapeData(outputData)

responseData = outputData.responseData;
positions = outputData.positions;

simpleResponses = [];

for p = 1:length(positions)
    r = responseData{p,1};
    spikes = mean(r(r(:,1) == 1.0, 2)); % just get the intensity 1.0 ones
    simpleResponses(end+1,1) = spikes;
end

xlist = positions(:,1);
ylist = positions(:,2);
zlist = simpleResponses;

centerOfMassXY = [0, 0];%outputData.centerOfMassXY;

largestDistanceOffset = max(max(abs(xlist)), max(abs(ylist)));
X = linspace(-1*largestDistanceOffset, largestDistanceOffset, 100);
Y = X;
%                 X = linspace(min(xlist), max(xlist), 40);
%                 Y = linspace(min(ylist), max(ylist), 40);

%                 ax = gca;
subplot(2,1,1)
[xq,yq] = meshgrid(X, Y);
vq = griddata(xlist, ylist, zlist, xq, yq);
%                 surf(xq, yq, vq, 'EdgeColor', 'none', 'FaceColor', 'interp');
pcolor(xq, yq, vq)
grid off
shading interp
hold on
plot3(xlist,ylist,zlist,'ok');
plot(centerOfMassXY(1), centerOfMassXY(2),'+r')
hold off
view(0, 90)
xlabel('X (um)');
ylabel('Y (um)');
axis equal
axis square
%                 colorbar;
title(centerOfMassXY);


%% plot time graph
spotOnTime = outputData.spotOnTime;
spotTotalTime = outputData.spotTotalTime;

%                 spikeBins = nodeData.spikeBins.value;
spotBinDisplay = mean(outputData.spikeRate_by_spot, 1);
displayTime = outputData.displayTime;
timeOffset = outputData.timeOffset;

subplot(2,1,2)
plot(displayTime, spotBinDisplay)
%                 plot(spikeBins(1:end-1), spikeBinsValues);
%                 xlim([0,spikeBins(end-1)])

title('Temporal offset calculation')

top = max(spotBinDisplay);

% two light spot patches
p = patch([0 spotOnTime spotOnTime 0],[0 0 top top],'y');
set(p,'FaceAlpha',0.3);
set(p,'EdgeColor','none');
p = patch(spotTotalTime+[0 spotOnTime spotOnTime 0],[0 0 top top],'y');
set(p,'FaceAlpha',0.3);
set(p,'EdgeColor','none');

% analysis spot patch
p = patch(min(displayTime)+[0 spotTotalTime spotTotalTime 0],[0 0 .1*top .1*top],'g');
set(p,'FaceAlpha',0.3);
set(p,'EdgeColor','none');

title(timeOffset)

end