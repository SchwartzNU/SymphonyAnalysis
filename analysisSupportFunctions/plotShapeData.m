function [] = plotShapeData(ad, mode)


function [] = printPresentationParams(ad)
    firstEpoch = ad.epochData{1};
    fprintf('num positions: %d\n', length(ad.positions));
    fprintf('num values: %d\n', firstEpoch.numValues);
    fprintf('num repeats: %d\n',firstEpoch.numValueRepeats);
    voltages = [];
    for i = 1:length(ad.epochData)
        voltages(i) = ad.epochData{i}.ampVoltage;
    end
    fprintf('holding voltages: %d\n', voltages');
end

if strcmp(mode,'spatial')
    
    printPresentationParams(ad)
    
    %% Plot spatial receptive field using responses from highest intensity spots
%     clf;
%     set(gcf, 'Name','Spatial RF','NumberTitle','off');

    ha = tight_subplot(2,2,.08);
    if ad.validSearchResult == 1

        dataNames = {'On','Off','Total'};
        titles = {'', 'On Off RF', 'Total RF'};
        colors = {'g';'r';'m'};
        positions = ad.positions;

        xlist = positions(:,1);
        ylist = positions(:,2);
%         largestDistanceOffset = max(max(abs(xlist)), max(abs(ylist)));
        largestDistanceOffset = 150;
        
        
        axes_by_ooi = [ha(1), ha(1), ha(2)];
        on_data_stored = [];
        
        for ooi = 1:3
            zlist = ad.maxIntensityResponses(:,ooi);

            X = linspace(-1*largestDistanceOffset, largestDistanceOffset, 100);
            Y = X;
            %                 X = linspace(min(xlist), max(xlist), 40);
            %                 Y = linspace(min(ylist), max(ylist), 40);

            %                 ax = gca;
            axes(axes_by_ooi(ooi));
            [xq,yq] = meshgrid(X, Y);
            vq = griddata(xlist, ylist, zlist, xq, yq);
            
            if ooi == 1
                on_data_stored = vq;
            else
                if ooi == 2 % use On as Green, Off as Red
                    c = vq;
                    c(:,:,2) = on_data_stored;
                    c(:,:,3) = 0;
%                     c(isnan(c)) = 0;
                    c = c ./ nanmax(c(:));
                else
                    c = vq;
                end
                surface(xq, yq, zeros(size(xq)), c)
            end
            grid off
            shading interp
            hold on

            % plot measured points
            plot3(xlist,ylist,zlist,'.','MarkerSize',5,'MarkerEdgeColor',[.7 .7 .7]);

            % plot gaussian ellipse
            % [Amplitude, x0, sigmax, y0, sigmay] = x;
            gfp = ad.gaussianFitParams_ooi{ooi};
            disp([dataNames{ooi}, ' center of gaussian fit: ' num2str([gfp('centerX'), gfp('centerY')]) ' um'])

            plot(gfp('centerX'), gfp('centerY'),colors{ooi},'MarkerSize',20, 'Marker','+')
            ellipse(gfp('sigma2X'), gfp('sigma2Y'), -gfp('angle'), gfp('centerX'), gfp('centerY'), colors{ooi});

            view(0, 90)
            set(gca,'XTickLabelMode','auto')
            set(gca,'YTickLabelMode','auto')
    %         xlabel('X (um)');
    %         ylabel('Y (um)');
            axis([-largestDistanceOffset,largestDistanceOffset,-largestDistanceOffset,largestDistanceOffset])
    %         axis equal
            axis square
            %                 colorbar;
            title(titles{ooi});
%             
%             if ooi == 3
%                 save('rf.mat', 'xq','yq','vq')
%             end
            
        end
        
    else
        subplot(2,1,1)
        title('No valid search epoch result')
    end


    %% plot time graph
    spotOnTime = ad.spotOnTime;
    spotTotalTime = ad.spotTotalTime;

    %                 spikeBins = nodeData.spikeBins.value;
    
    spotBinDisplay = mean(ad.spikeRate_by_spot, 1);
    timeOffset = ad.timeOffset;
    
    displayTime = (1:(ad.sampleRate * spotTotalTime)) ./ ad.sampleRate + timeOffset(1);

    axes(ha(3))
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
    p = patch(ad.timeOffset(1)+[0 spotOnTime spotOnTime 0],[0 0 -.1*top -.1*top],'g');
    set(p,'FaceAlpha',0.3);
    set(p,'EdgeColor','none');
    p = patch(ad.timeOffset(1)+[spotOnTime spotTotalTime spotTotalTime spotOnTime],[0 0 -.1*top -.1*top],'r');
    set(p,'FaceAlpha',0.3);
    set(p,'EdgeColor','none');    

    title(['temporal offset of collection bins (on, off): ' num2str(timeOffset) ' sec'])
    
elseif strcmp(mode, 'subunit')

    if ad.numValues > 1
    
        %% Plot figure with subunit models
    %     figure(12);
        num_positions = size(ad.responseData,1);
        dim1 = floor(sqrt(num_positions));
        dim2 = ceil(num_positions / dim1);

        distance_to_center = zeros(num_positions, 1);
        for p = 1:num_positions
            gfp = ad.gaussianFitParams_ooi{3};
            distance_to_center(p,1) = sqrt(sum((ad.positions(p,:) - [gfp('centerX'),gfp('centerY')]).^2));
        end
        sorted_positions = sortrows([distance_to_center, (1:num_positions)'], 1);

        ha = tight_subplot(dim1,dim2);
        
        for p = 1:num_positions
%             tight_subplot(dim1,dim2,p)
            axes(ha(p))
            resp_index = sorted_positions(p,2);
            responses = ad.responseData{resp_index,3};
            responses = sortrows(responses, 1); % order by intensity values for plot
            intensity = responses(:,1);
            rate = responses(:,2);
            plot(intensity, rate, 'o')
            hold on
            if length(unique(intensity)) > 1
                pfit = polyfit(intensity, rate, 1);
                plot(intensity, polyval(pfit,intensity))
            end
%             ylim([0,max(rate)+.1])
            hold off
        end
        
        set(ha(1:end-dim2),'XTickLabel','');
%         set(ha,'YTickLabel','')
    else
        disp('No multiple value subunits measured');
    end
    
elseif strcmp(mode, 'temporalAlignment')    
    ei = ad.alignmentEpochIndex;
    if ~isnan(ei)
        t = ad.epochData{ei}.t;
        hold on
        plot(t, ad.alignmentRate ./ max(ad.alignmentRate),'r');
        plot(t, ad.alignmentLightOn,'b')
        plot(t + ad.timeOffset(1), ad.alignmentLightOn * .8,'g')
        legend('rate','light','shifted')
        title(ad.timeOffset(1))
        hold off
    end
elseif strcmp(mode, 'wholeCell')
    obs = ad.observations;
   
    maxIntensity = max(obs(:,3));
    v_in = max(obs(:,4));
    v_ex = min(obs(:,4));
    
    positions = [];
    r_ex = [];
    r_in = [];
    
    for poi = 1:length(ad.positions)
        pos = ad.positions(poi,:);
        obs_sel = ismember(obs(:,1:2), pos, 'rows');
        obs_sel = obs_sel & obs(:,3) == maxIntensity;
        obs_sel_ex = obs_sel & obs(:,4) == v_ex;
        obs_sel_in = obs_sel & obs(:,4) == v_in;
        r_ex(poi,1) = mean(obs(obs_sel_ex,5),1);
        r_in(poi,1) = mean(obs(obs_sel_in,5),1);
        positions(poi,:) = pos;
    end
    h = max(abs(vertcat(r_ex,r_in)));
%     r_ex = r_ex - min(r_ex);
    r_ex = r_ex / h;
    
%     r_in = r_in - min(r_in);
    r_in = r_in / h;
    
    
    largestDistanceOffset = max(abs(obs(:,1)));
    X = linspace(-1*largestDistanceOffset, largestDistanceOffset, 100);
    [xq,yq] = meshgrid(X, X);
    c_ex = griddata(positions(:,1), positions(:,2), r_ex, xq, yq);
    c_in = griddata(positions(:,1), positions(:,2), r_in, xq, yq);
    
    c = c_ex;
    c(:,:,2) = c_in;
    c(:,:,3) = 0;
    surface(xq, yq, zeros(size(xq)), c)
    grid off
    axis square
    axis equal
    
    shading interp
else
    disp('incorrect plot type')
end


end