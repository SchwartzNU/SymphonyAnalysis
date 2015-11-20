function [] = plotShapeData(od, mode)


if strcmp(mode,'spatial')
    %% Plot spatial receptive field using responses from highest intensity spots
    clf;
    ha = tight_subplot(2,1,.05);    
    if od.validSearchResult == 1

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
        axes(ha(1))
        [xq,yq] = meshgrid(X, Y);
        vq = griddata(xlist, ylist, zlist, xq, yq);
        %                 surf(xq, yq, vq, 'EdgeColor', 'none', 'FaceColor', 'interp');
        pcolor(xq, yq, vq)
        grid off
        shading interp
        hold on
        
        % plot measured points
        plot3(xlist,ylist,zlist,'.','MarkerSize',5,'MarkerEdgeColor',[.7 .7 .7]);
        
        % plot gaussian ellipse
        % [Amplitude, x0, sigmax, y0, sigmay] = x;
        gfp = od.gaussianFitParams;
        plot(gfp('centerX'), gfp('centerY'),'+r','MarkerSize',20)
        
        ellipse(gfp('sigma2X'), gfp('sigma2Y'), -gfp('angle'), gfp('centerX'), gfp('centerY'), 'g');
        
        view(0, 90)
        xlabel('X (um)');
        ylabel('Y (um)');
        axis([-largestDistanceOffset,largestDistanceOffset,-largestDistanceOffset,largestDistanceOffset])
%         axis equal
        axis square
        %                 colorbar;
        title(['center of gaussian fit: ' num2str([gfp('centerX'), gfp('centerY')]) ' um']);
        hold off
    else
        subplot(2,1,1)
        title('No valid search epoch result')
    end


    %% plot time graph
    spotOnTime = od.spotOnTime;
    spotTotalTime = od.spotTotalTime;

    %                 spikeBins = nodeData.spikeBins.value;
    spotBinDisplay = mean(od.spikeRate_by_spot, 1);
    displayTime = od.displayTime;
    timeOffset = od.timeOffset;


    axes(ha(2))
    plot(displayTime, spotBinDisplay)
    %                 plot(spikeBins(1:end-1), spikeBinsValues);
    %                 xlim([0,spikeBins(end-1)])

    title('Temporal offset calculation')

    top = max(spotBinDisplay)*1.1;

    % two light spot patches
    p = patch([0 spotOnTime spotOnTime 0],[0 0 top top],'y');
    set(p,'FaceAlpha',0.3);
    set(p,'EdgeColor','none');
    p = patch(spotTotalTime+[0 spotOnTime spotOnTime 0],[0 0 top top],'y');
    set(p,'FaceAlpha',0.3);
    set(p,'EdgeColor','none');

    % analysis spot patch
    p = patch(od.timeOffset+[0 spotTotalTime spotTotalTime 0],[0 0 -.1*top -.1*top],'g');
    set(p,'FaceAlpha',0.3);
    set(p,'EdgeColor','none');

    title(['temporal offset of collection bins: ' num2str(timeOffset) ' sec'])
    
elseif strcmp(mode, 'subunit')

    if od.numValues > 1
    
        %% Plot figure with subunit models
    %     figure(12);
        clf;
        num_positions = size(od.responseData,1);
        dim1 = floor(sqrt(num_positions));
        dim2 = ceil(num_positions / dim1);

        distance_to_center = zeros(num_positions, 1);
        for p = 1:num_positions
            distance_to_center(p,1) = sqrt(sum((od.positions(p,:) - [od.gaussianFitParams('centerX'),od.gaussianFitParams('centerY')]).^2));
        end
        sorted_positions = sortrows([distance_to_center, (1:num_positions)'], 1);

        ha = tight_subplot(dim1,dim2);
        
        for p = 1:num_positions
%             tight_subplot(dim1,dim2,p)
            axes(ha(p))
            resp_index = sorted_positions(p,2);
            responses = od.responseData{resp_index,1};
            responses = sortrows(responses, 1); % order by intensity values for plot
            intensity = responses(:,1);
            rate = responses(:,2);          
            plot(intensity, rate)
            hold on
            pfit = polyfit(intensity, rate, 1);
            plot(intensity, polyval(pfit,intensity))
            ylim([0,max(rate)+.1])
            hold off
        end
        
        set(ha(1:end-dim2),'XTickLabel','');
        set(ha,'YTickLabel','')
    else
        disp('No multiple value subunits measured');
    end
else
    disp('incorrect plot type')
end


end