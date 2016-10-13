

if useSubunits
    
    c_subunitSigma = c_subunit2SigmaWidth / 2;
    c_subunitSigma_surround = c_subunit2SigmaWidth_surround / 2;
    c_subunitCenters = {};
    for vi = 1:2
        c_subunitCenters{vi} = generatePositions('triangular', [c_extent, c_subunitSpacing(vi), 0]);
        c_numSubunits(vi) = size(c_subunitCenters{vi},1);
    end

    % subunit RF profile, using gaussian w/ set radius (function)
    c_subunitRf = {};
    for vi = 1:2
        c_subunitRf{vi} = zeros(sim_dims(2), sim_dims(3), c_numSubunits(vi));
        for si = 1:c_numSubunits(vi)
            center = c_subunitCenters{vi}(si,:);
            dmap = (mapX - center(1)).^2 + (mapY - center(2)).^2; % no sqrt, so
            rf_c = exp(-(dmap / (2 * c_subunitSigma(vi) .^ 2))); % no square
            rf_s = exp(-(dmap / (2 * c_subunitSigma_surround(vi) .^ 2))); % no square

            rf = rf_c - c_subunitSurroundRatio(vi) * rf_s;
            rf = rf ./ max(rf(:));
            c_subunitRf{vi}(:,:,si) = rf;
        end
    end

    % calculate connection strength for each subunit, for each voltage
    s_subunitStrength = {};
    for vi = 1:e_numVoltages
        s_subunitStrength{vi} = zeros(c_numSubunits(vi),1);
        for si = 1:c_numSubunits(vi)

            rfmap = e_map(:,:,vi);
            sumap = c_subunitRf{vi}(:,:,si);
            [~,I] = max(sumap(:));
            [x,y] = ind2sub([sim_dims(2), sim_dims(3)], I);

            s_subunitStrength{vi}(si) = rfmap(x,y);

    %         todo: change it to a regression between map and each subunit as a predictor
    %         s_subunitStrength{vi}(si) = sum(rfmap(:) ./ sumap(:));
        end
    end

    % remove unconnected subunits
    for vi = 1:e_numVoltages
        nullSubunits = s_subunitStrength{vi} < eps+.1;
        c_subunitRf{vi}(:,:,nullSubunits) = [];
        s_subunitStrength{vi}(nullSubunits) = [];
        c_subunitCenters{vi}(nullSubunits',:) = [];
        c_numSubunits(vi) = size(s_subunitStrength{vi},1);
    end
    
else % single complete subunit
    c_subunitRf = {};
    s_subunitStrength = {};
    c_numSubunits = [];
    for vi = 1:2
        c_subunitRf{vi}(:,:,1) = e_map(:,:,vi);
        s_subunitStrength{vi}(1) = 1;
        c_numSubunits(vi) = 1;
    end
       
end

% plot the spatial graphs
if plotSpatialGraphs
    for vi = 1:e_numVoltages
        axes(axesSpatialData((vi - 1) * 2 + 2))
    %     imagesc(sum(c_subunitRf, 3))
        d = zeros(sim_dims(2), sim_dims(3));
        for si = 1:c_numSubunits(vi)
            d = d + c_subunitRf{vi}(:,:,si) * s_subunitStrength{vi}(si);
        end
        plotSpatialData(mapX,mapY,d)
        axis equal
        axis tight
%         title('all subunits scaled by maps')
        hold on
%         xlabel('µm')
%         ylabel('µm')
        % plot points at the centers of subunits
        if c_numSubunits(vi) > 1
            plot(c_subunitCenters{vi}(:,1), c_subunitCenters{vi}(:,2),'r.')
        end
        
    end
    drawnow
end
