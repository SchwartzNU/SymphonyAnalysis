function [] = plotShapeData(ad, mode)


if strcmp(mode, 'printParameters')
    firstEpoch = ad.epochData{1};
    fprintf('num positions: %d\n', length(ad.positions));
    fprintf('num values: %d\n', firstEpoch.numValues);
    fprintf('num repeats: %d\n',firstEpoch.numValueRepeats);
    voltages = [];
    for i = 1:length(ad.epochData)
        voltages(i) = ad.epochData{i}.ampVoltage;
    end
    fprintf('holding voltages: %d\n', voltages');

    disp(ad);

elseif strncmp(mode, 'plotSpatial', 11)
% elseif strcmp(mode, 'plotSpatial_tHalfMax')
    if strfind(mode, 'mean')
        mode_col = 5;
        smode = 'mean';
    elseif strfind(mode, 'peak')
        mode_col = 6;
        smode = 'peak';
    elseif strfind(mode, 'tHalfMax')
        mode_col = 7;
        smode = 't half max';
    end
    
    if ~isfield(ad,'observations')
        return
    end
    obs = ad.observations;
    if isempty(obs)
        return
    end
    
    voltages = unique(obs(:,4));
    num_voltages = length(voltages);
        
    intensities = unique(obs(:,3));
    num_intensities = length(intensities);
    
    ha = tight_subplot(num_intensities, num_voltages);
    for vi = 1:num_voltages
        for ii = 1:num_intensities
            intensity = intensities(ii);
            voltage = voltages(vi);
            
%             vals = zeros(length(ad.positions),1);
            vals = [];
            posIndex = 0;
            goodPositions = [];
            for poi = 1:length(ad.positions)
                pos = ad.positions(poi,:);
                obs_sel = ismember(obs(:,1:2), pos, 'rows');
                obs_sel = obs_sel & obs(:,3) == intensity;
                obs_sel = obs_sel & obs(:,4) == voltage;
                val = nanmean(obs(obs_sel, mode_col),1);
                if any(obs_sel) && ~isnan(val)
                    posIndex = posIndex + 1;
                    vals(posIndex,1) = val;
                    goodPositions(posIndex,:) = pos;
                end
            end
            
            a = vi + (ii-1) * num_voltages;
            
            axes(ha(a));
            plotSpatial(goodPositions, vals, sprintf('%s at V = %d mV, intensity = %f', smode, voltage, intensity), 1, 1, ad.positionOffset);
%             caxis([0, max(vals)]);
%             colormap(flipud(colormap))

        end
    end
    
    
elseif strcmp(mode, 'subunit')

%     if ad.numValues > 1
    
        %% Plot figure with subunit models
    %     figure(12);


%         distance_to_center = zeros(num_positions, 1);
%         for p = 1:num_positions
%             gfp = ad.gaussianFitParams_ooi{3};
%             distance_to_center(p,1) = sqrt(sum((ad.positions(p,:) - [gfp('centerX'),gfp('centerY')]).^2));
%         end
%         sorted_positions = sortrows([distance_to_center, (1:num_positions)'], 1);


        num_positions = size(ad.positions,1);
        dim1 = floor(sqrt(num_positions));
        dim2 = ceil(num_positions / dim1);
        
        ha = tight_subplot(dim1,dim2);
        
        obs = ad.observations;
        if isempty(obs)
            return
        end
        voltages = unique(obs(:,4));
        num_voltages = length(voltages);
        
        for p = 1:num_positions
%             tight_subplot(dim1,dim2,p)
            axes(ha(p))
            hold on
            
            pos = ad.positions(p,:);
            obs_sel = ismember(obs(:,1:2), pos, 'rows');
            
            for vi = 1:num_voltages
                voltage = voltages(vi);
                obs_sel_v = obs_sel & obs(:,4) == voltage;
            
                responses = obs(obs_sel_v, 5); % peak: 6, mean: 5
                intensities = obs(obs_sel_v, 3);

                plot(intensities, responses, 'o')
                if length(unique(intensities)) > 1
                    pfit = polyfit(intensities, responses, 1);
                    plot(intensities, polyval(pfit,intensities))
                end
    %             ylim([0,max(rate)+.1])
            end
            grid on
            hold off

        end
        
%         set(ha(1:end-dim2),'XTickLabel','');
%         set(ha,'YTickLabel','')
%     else
%         disp('No multiple value subunits measured');
%     end
    
elseif strcmp(mode, 'temporalResponses')
    num_plots = length(ad.epochData);
    ha = tight_subplot(num_plots, 1, .1);
    
    for ei = 1:num_plots
        plot(ha(ei), ad.epochData{ei}.t, ad.epochData{ei}.response);
        title(ha(ei), sprintf('Epoch %d', ei))
    end
    
elseif strcmp(mode, 'temporalAlignment')    
    
    ha = tight_subplot(2, 1, .1);
    
    ei = ad.alignmentEpochIndex;
    axes(ha(1));
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
    
    
    %% plot time graph
    axes(ha(2));
    spotOnTime = ad.spotOnTime;
    spotTotalTime = ad.spotTotalTime;

    %                 spikeBins = nodeData.spikeBins.value;
    
    
    % get average of all responses
    obs = ad.observations;
    if isempty(obs)
        return;
    end
    sm = [];
    for oi = 1:size(obs, 1)
        
        entry = obs(oi,:)';
        epoch = ad.epochData{entry(9)};

        sm(oi,:) = epoch.response(entry(10):entry(11));
    end
    spotBinDisplay = mean(sm,1);
    
%     spotBinDisplay = mean(ad.spikeRate_by_spot, 1);
    timeOffset = ad.timeOffset;
    
    displayTime = (1:length(spotBinDisplay)) ./ ad.sampleRate + timeOffset(1);
    
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

elseif strcmp(mode, 'responsesByPosition')
    
    obs = ad.observations;
   
    maxIntensity = max(obs(:,3));
    v_in = max(obs(:,4));
    v_ex = min(obs(:,4));    
    
    num_positions = size(ad.positions,1);
    dim1 = floor(sqrt(num_positions));
    dim2 = ceil(num_positions / dim1);

    ha = tight_subplot(dim1, dim2, .01, .01);    
    
    max_value = -inf;
    min_value = inf;
    
    for poi = 1:num_positions
        pos = ad.positions(poi,:);
        obs_sel = ismember(obs(:,1:2), pos, 'rows');
        obs_sel = obs_sel & obs(:,3) == maxIntensity;
        obs_sel_ex = obs_sel & obs(:,4) == v_ex;
        ind_ex = find(obs_sel_ex);
        obs_sel_in = obs_sel & obs(:,4) == v_in;
        ind_in = find(obs_sel_in);
        
        hold(ha(poi), 'on');
        for ii = ind_ex'
            entry = obs(ii,:)';
            epoch = ad.epochData{entry(9)};
            
            signal = -3 * epoch.response(entry(10):entry(11));
%             signal = signal - mean(signal(1:10));
            plot(ha(poi), signal,'r');
            
            max_value = max(max_value, max(signal));
            min_value = min(min_value, min(signal));
        end
        
        for ii = ind_in'
            entry = obs(ii,:)';
            epoch = ad.epochData{entry(9)};
            
            signal = epoch.response(entry(10):entry(11));
            signal = signal - mean(signal(1:10));
            plot(ha(poi), signal,'b');
            
            max_value = max(max_value, max(signal));
            min_value = min(min_value, min(signal));
        end        
        
%         set(gca,'XTickLabelMode','manual')
        set(ha(poi),'XTickLabels',[])
        if poi > 1
            set(ha(poi),'YTickLabels',[])
        end
        

%         title(ha(poi), pos);
        
    end
    linkaxes(ha)
    ylim(ha(1), [min_value, max_value]);
%     xlim(ha(1), [signal(1), signal(end)])
    
elseif strcmp(mode, 'wholeCell')
    obs = ad.observations;
   
    maxIntensity = max(obs(:,3));
    v_in = max(obs(:,4));
    v_ex = min(obs(:,4));
    
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
    end
    v_reversal_ex = 0;
    v_reversal_in = -60;
    r_ex = r_ex ./ abs(v_ex - v_reversal_ex);
    r_in = r_in ./ abs(v_in - v_reversal_in);
    r_exinrat = r_ex - r_in;
%     r_exinrat = sign(r_exinrat) .* log10(abs(r_exinrat));
    
    max_ = max(vertcat(r_ex, r_in));
    min_ = min(vertcat(r_ex, r_in));

    ha = tight_subplot(1,3);

    % EX
    axes(ha(1))
    plotSpatial(ad.positions, r_ex, sprintf('Excitatory conductance: %d mV', v_ex), 1, 1, ad.positionOffset)
%     caxis([min_, max_]);
    
    % IN
    axes(ha(2))
    plotSpatial(ad.positions, r_in, sprintf('Inhibitory conductance: %d mV', v_in), 1, 1, ad.positionOffset)
%     caxis([min_, max_]);
    
    % Ratio    
    axes(ha(3))
    plotSpatial(ad.positions, r_exinrat, 'Ex/In difference', 1, 0, ad.positionOffset)
    

elseif strcmp(mode, 'spatialDiagnostics')
    obs = ad.observations;
    if isempty(obs)
        return
    end
    voltages = unique(obs(:,4));
    num_voltages = length(voltages);
        
    % variance by point value at max value
    maxIntensity = max(obs(:,3));
    
    ha = tight_subplot(1, num_voltages);
    for vi = 1:num_voltages
        voltage = voltages(vi);
        vals = [];
        for poi = 1:length(ad.positions)
            pos = ad.positions(poi,:);
            obs_sel = ismember(obs(:,1:2), pos, 'rows');
            obs_sel = obs_sel & obs(:,3) == maxIntensity;
            obs_sel = obs_sel & obs(:,4) == voltage;
            vals(poi,1) = std(obs(obs_sel,5),1) / mean(obs(obs_sel,5),1);
        end    
        axes(ha(vi));
        plotSpatial(ad.positions, vals, sprintf('STD/mean at V = %d mV', voltage), 1, 0, ad.positionOffset)
%         caxis([0, max(vals)]);
    end
    
    
%     diagTxt = uicontrol('style','text');
%     diagTxt.HorizontalAlignment = 'left';
%     diagTxt.Units = 'characters';
%     diagTxt.Position = [0, 0, 30, 10];
%     align([diagTxt, h],'Distribute','Top')
%     
%     diagTxt.String = 'Hello World';
    
elseif strcmp(mode, 'positionDifferenceAnalysis')
    obs = ad.observations;
    if isempty(obs)
        return
    end
    
    % general distance to value
    subplot(2,1,1)
    plot(obs(:,8), obs(:,5), 'o')
    hold on
    sel = ~isnan(obs(:,8)) & ~isnan(obs(:,5));
    p = polyfit(obs(sel,8), obs(sel,5), 1);
    plot(obs(:,8), polyval(p, obs(:,8)))
    hold off
    
    % compare repeat values with different distances
    subplot(2,1,2)
    
    
else
    disp(mode)
    disp('incorrect plot type')
end

    function plotSpatial(positions, values, titl, addcolorbar, gaussianfit, positionOffset)
        positions = bsxfun(@plus, positions, positionOffset);
        largestDistanceOffset = max(abs(positions(:)));
        X = linspace(-1*largestDistanceOffset, largestDistanceOffset, 100);
        [xq,yq] = meshgrid(X, X);        
        c = griddata(positions(:,1), positions(:,2), values, xq, yq);
        surface(xq, yq, zeros(size(xq)), c)
        title(titl)
        grid off
    %     axis square
        axis equal
        shading interp
        if addcolorbar
            colorbar
        end
        if gaussianfit
            hold on
            gfp = fit2DGaussian(positions, values);
%             disp([dataNames{ooi}, ' center of gaussian fit: ' num2str([gfp('centerX'), gfp('centerY')]) ' um'])

            plot(gfp('centerX'), gfp('centerY'),'red','MarkerSize',20, 'Marker','+')
            ellipse(gfp('sigma2X'), gfp('sigma2Y'), -gfp('angle'), gfp('centerX'), gfp('centerY'), 'red');
            hold off
        end
        
        % draw soma
        rectangle('Position',[0, 0, 10, 10],'Curvature',1,'FaceColor',[1 0 1]);
        
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
        set(gca, 'YTickMode', 'auto', 'YTickLabelMode', 'auto')
    end

end