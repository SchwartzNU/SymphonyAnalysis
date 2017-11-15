
stim_filterGaussianSigma = 50; % in microns

% t, x, y
for optionIndex = 1:stim_numOptions
    stim_lightMatrixFiltered = zeros(sim_dims);
    for ti = 1:length(T)
        frame = squeeze(stim_lightMatrix_byOption{optionIndex}(ti, :, :));
        lowpass = imgaussfilt(frame, stim_filterGaussianSigma / sim_spaceResolution);
        stim_lightMatrixFiltered(ti,:,:) = frame - 1.1*lowpass;
    end
    stim_lightMatrix_byOption{optionIndex} = stim_lightMatrixFiltered;
end

if 0
    %%
    figure(78);
    set(gcf, 'Name','Stimulus Movie Display','NumberTitle','off');
    clf;
    for ti = 1:length(T)
        sim_light = squeeze(stim_lightMatrix(ti, :, :));
%         subplot(1,2,1);
        plotSpatialData(mapX,mapY,sim_light);
        colormap gray
        caxis([-2,2])
        colorbar
%         plot(squeeze(stim_lightMatrix(ti, 1, :)));
        
        
%         sim_light = squeeze(stim_lightMatrixFiltered(ti, :, :));
%         subplot(1,2,2);
%         plotSpatialData(mapX,mapY,sim_light);
%         colormap gray
%         caxis([-2,2])
%         colorbar        
% 
% %         plot(squeeze(stim_lightMatrixFiltered(ti, 1, :)));
        title(sprintf('stimulus at %.3f sec', T(ti)));
        axis tight
        drawnow
        %             pause(sim_timeStep)
        
    end
end
