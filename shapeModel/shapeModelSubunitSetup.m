

if useSubunits
    
    c_subunitSigma = c_subunit2SigmaWidth / 2;
    c_subunitSigma_surround = c_subunit2SigmaWidth_surround / 2;
    c_subunitCenters = {};
    for vi = 1:2
        for ooi = 1:2
            c_subunitCenters{vi,ooi} = generatePositions('triangular', [c_extent, c_subunitSpacing(vi,ooi), 0]);
            c_numSubunits(vi,ooi) = size(c_subunitCenters{vi,ooi},1);
        end
    end

    % subunit RF profile, using gaussian w/ set radius (function)
    c_subunitRf = {};
    for vi = 1:2
        for ooi = 1:2
            c_subunitRf{vi,ooi} = zeros(sim_dims(2), sim_dims(3), c_numSubunits(vi,ooi));
            for si = 1:c_numSubunits(vi)
                center = c_subunitCenters{vi,ooi}(si,:);
                dmap = (mapX - center(1)).^2 + (mapY - center(2)).^2; % no sqrt, so
                rf_c = exp(-(dmap / (2 * c_subunitSigma(vi,ooi) .^ 2))); % no square
                rf_s = exp(-(dmap / (2 * c_subunitSigma_surround(vi,ooi) .^ 2))); % no square

                rf = rf_c - c_subunitSurroundRatio(vi,ooi) * rf_s;
                rf = rf ./ max(rf(:));
                c_subunitRf{vi,ooi}(:,:,si) = rf;
            end
        end
    end

    % calculate connection strength for each subunit, for each voltage
    s_subunitStrength = {};
    for vi = 1:e_numVoltages
        for ooi=1:2
            s_subunitStrength{vi,ooi} = zeros(c_numSubunits(vi,ooi),1);
            for si = 1:c_numSubunits(vi,ooi)

                rfmap = e_map(:,:,vi,ooi);
                sumap = c_subunitRf{vi,ooi}(:,:,si);
                [~,I] = max(sumap(:));
                [x,y] = ind2sub([sim_dims(2), sim_dims(3)], I);

                s_subunitStrength{vi,ooi}(si) = rfmap(x,y);

        %         todo: change it to a regression between map and each subunit as a predictor
        %         s_subunitStrength{vi}(si) = sum(rfmap(:) ./ sumap(:));
            end
        end
    end

    % remove unconnected subunits
    for vi = 1:e_numVoltages
        for ooi=1:2
            nullSubunits = s_subunitStrength{vi,ooi} < eps+.1;
            c_subunitRf{vi,ooi}(:,:,nullSubunits) = [];
            s_subunitStrength{vi,ooi}(nullSubunits) = [];
            c_subunitCenters{vi,ooi}(nullSubunits',:) = [];
            c_numSubunits(vi,ooi) = size(s_subunitStrength{vi,ooi},1);
        end
    end
    
else % single complete subunit
    c_subunitRf = {};
    s_subunitStrength = {};
    c_numSubunits = [];
    for vi = 1:2
        for ooi = 1:2
            c_subunitRf{vi,ooi}(:,:,1) = e_map(:,:,vi,ooi);
            s_subunitStrength{vi,ooi}(1) = 1;
            c_numSubunits(vi,ooi) = 1;
        end
    end
       
end

% plot the spatial graphs
if plotSpatialGraphs
    for vi = 1:e_numVoltages
        for ooi = 1:2
            axes(axesSpatialData((vi - 1) * 3 + 1 + ooi))
            d = zeros(sim_dims(2), sim_dims(3));
            for si = 1:c_numSubunits(vi,ooi)
                d = d + c_subunitRf{vi, ooi}(:,:,si) * s_subunitStrength{vi, ooi}(si);
            end
            plotSpatialData(mapX,mapY,d)
            axis equal
            axis tight
            a = {'on','off'};
            title(a{ooi})
    %         title('all subunits scaled by maps')
            hold on
    %         xlabel('µm')
    %         ylabel('µm')
            % plot points at the centers of subunits
            if c_numSubunits(vi,ooi) > 1
                plot(c_subunitCenters{vi}(:,1), c_subunitCenters{vi}(:,2),'r.')
            end
        end
    end
    drawnow
end
