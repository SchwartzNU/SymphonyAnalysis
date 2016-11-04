

if useSubunits
    
    c_subunitSigma = c_subunit2SigmaWidth / 2;
    c_subunitSigma_surround = c_subunit2SigmaWidth_surround / 2;
    c_subunitCenters = {};
    for vi = 1:2
        for oi = 1:2
            c_subunitCenters{vi,oi} = generatePositions('triangular', [c_extent, c_subunitSpacing(vi,oi), 0]);
            c_numSubunits(vi,oi) = size(c_subunitCenters{vi,oi},1);
        end
    end

    % subunit RF profile, using gaussian w/ set radius (function)
    c_subunitRf = {};
    for vi = 1:2
        for oi = 1:2
            c_subunitRf{vi,oi} = zeros(sim_dims(2), sim_dims(3), c_numSubunits(vi,oi));
            for si = 1:c_numSubunits(vi)
                center = c_subunitCenters{vi,oi}(si,:);
                dmap = (mapX - center(1)).^2 + (mapY - center(2)).^2; % no sqrt, so
                rf_c = exp(-(dmap / (2 * c_subunitSigma(vi,oi) .^ 2))); % no square
                rf_s = exp(-(dmap / (2 * c_subunitSigma_surround(vi,oi) .^ 2))); % no square

                rf = rf_c - c_subunitSurroundRatio(vi,oi) * rf_s;
                rf = rf ./ max(rf(:));
                c_subunitRf{vi,oi}(:,:,si) = rf;
            end
        end
    end

    % calculate connection strength for each subunit, for each voltage
    s_subunitStrength = {};
    for vi = 1:e_numVoltages
        for oi=1:2
            s_subunitStrength{vi,oi} = zeros(c_numSubunits(vi,oi),1);
            for si = 1:c_numSubunits(vi,oi)

                rfmap = e_map(:,:,vi,oi);
                sumap = c_subunitRf{vi,oi}(:,:,si);
                [~,I] = max(sumap(:));
                [x,y] = ind2sub([sim_dims(2), sim_dims(3)], I);

                s_subunitStrength{vi,oi}(si) = rfmap(x,y);

        %         todo: change it to a regression between map and each subunit as a predictor
        %         s_subunitStrength{vi}(si) = sum(rfmap(:) ./ sumap(:));
            end
        end
    end

    % remove unconnected subunits
    for vi = 1:e_numVoltages
        for oi=1:2
            nullSubunits = s_subunitStrength{vi,oi} < eps+.1;
            c_subunitRf{vi,oi}(:,:,nullSubunits) = [];
            s_subunitStrength{vi,oi}(nullSubunits) = [];
            c_subunitCenters{vi,oi}(nullSubunits',:) = [];
            c_numSubunits(vi,oi) = size(s_subunitStrength{vi,oi},1);
        end
    end
    
else % single complete subunit
    c_subunitRf = {};
    s_subunitStrength = {};
    c_numSubunits = [];
    for vi = 1:2
        for oi = 1:2
            c_subunitRf{vi,oi}(:,:,1) = e_map(:,:,vi,oi);
            s_subunitStrength{vi,oi}(1) = 1;
            c_numSubunits(vi,oi) = 1;
        end
    end
       
end

% plot the spatial graphs
if plotSpatialGraphs
    for vi = 1:e_numVoltages
        for oi = 1:2
            axes(axesSpatialData((vi - 1) * 3 + 1 + oi))
        %     imagesc(sum(c_subunitRf, 3))
            d = zeros(sim_dims(2), sim_dims(3));
            for si = 1:c_numSubunits(vi,oi)
                d = d + c_subunitRf{vi}(:,:,si) * s_subunitStrength{vi}(si);
            end
            plotSpatialData(mapX,mapY,d)
            axis equal
            axis tight
            a = {'on','off'};
            title(a{oi})
    %         title('all subunits scaled by maps')
            hold on
    %         xlabel('µm')
    %         ylabel('µm')
            % plot points at the centers of subunits
            if c_numSubunits(vi,oi) > 1
                plot(c_subunitCenters{vi}(:,1), c_subunitCenters{vi}(:,2),'r.')
            end
        end
    end
    drawnow
end
