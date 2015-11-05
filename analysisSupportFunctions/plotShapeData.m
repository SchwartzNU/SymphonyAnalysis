function [] = plotShapeData(od, mode)

if strcmp(mode,'spatial')
    %% Plot spatial receptive field using responses from highest intensity spots
    positions = od.positions;

    xlist = positions(:,1);
    ylist = positions(:,2);
    zlist = od.maxIntensityResponses;


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
    plot3(xlist,ylist,zlist,'.w','MarkerSize',5);
    plot(od.centerOfMassXY(1), od.centerOfMassXY(2),'+r','MarkerSize',30)
    hold off
    view(0, 90)
    xlabel('X (um)');
    ylabel('Y (um)');
    axis equal
    axis square
    %                 colorbar;
    title(od.centerOfMassXY);


    %% plot time graph
    spotOnTime = od.spotOnTime;
    spotTotalTime = od.spotTotalTime;

    %                 spikeBins = nodeData.spikeBins.value;
    spotBinDisplay = mean(od.spikeRate_by_spot, 1);
    displayTime = od.displayTime;
    timeOffset = od.timeOffset;

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

if strcmp(mode, 'subunit')

    %% Plot figure with subunit models
%     figure(12);clf;
    num_positions = size(od.responseData,1);
    dim1 = floor(sqrt(num_positions));
    dim2 = ceil(num_positions / dim1);

    distance_to_center = zeros(num_positions, 1);
    for p = 1:num_positions
        distance_to_center(p,1) = sqrt(sum((od.positions(p,:) - od.centerOfMassXY).^2));
    end
    sorted_positions = sortrows([distance_to_center, (1:num_positions)'], 1);

    for p = 1:num_positions
        subplot(dim1,dim2,p)
        resp_index = sorted_positions(p,2);
        responses = od.responseData{resp_index,1};
        responses = sortrows(responses, 1); % order by intensity values for plot
        intensity = responses(:,1);
        rate = responses(:,2);
        plot(intensity, rate)
    end
end


end