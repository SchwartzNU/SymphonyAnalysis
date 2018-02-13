%% Secondary analysis


%% SMS peak and tail
for ci = 1:size(dtab,1)
    spotSize = dtab{ci, 'SMS_mean0_spotSize_sp'}{1};
    if ~isempty(spotSize)
        onspikes = dtab{ci, 'SMS_mean0_onSpikes'}{1};
        offspikes = dtab{ci, 'SMS_mean0_offSpikes'}{1};
        [m, mi] = max(onspikes);
        peakValueOn(ci) = m;
        peakSizeOn(ci) = spotSize(mi);
        tailSpikesOn(ci) = mean(onspikes(spotSize > 550));
        [m, mi] = max(offspikes);
        peakValueOff(ci) = m;
        peakSizeOff(ci) = spotSize(mi);
        tailSpikesOff(ci) = mean(offspikes(spotSize > 550));        
    else
        peakValueOn(ci) = nan;
        peakSizeOn(ci) = nan;
        tailSpikesOn(ci) = nan;
        peakValueOff(ci) = nan;
        peakSizeOff(ci) = nan;
        tailSpikesOff(ci) = nan;                
    end
end

dtab{:,'SMS_onSpikes_prefSize'} = peakSizeOn';
dtabColumns{'SMS_onSpikes_prefSize', 'type'} = {'single'};
dtab{:,'SMS_onSpikes_peakSpikes'} = peakValueOn';
dtabColumns{'SMS_onSpikes_peakSpikes', 'type'} = {'single'};
dtab{:,'SMS_onSpikes_tailSpikes'} = tailSpikesOn';
dtabColumns{'SMS_onSpikes_tailSpikes', 'type'} = {'single'};
dtab{:,'SMS_offSpikes_prefSize'} = peakSizeOff';
dtabColumns{'SMS_offSpikes_prefSize', 'type'} = {'single'};
dtab{:,'SMS_offSpikes_peakSpikes'} = peakValueOff';
dtabColumns{'SMS_offSpikes_peakSpikes', 'type'} = {'single'};
dtab{:,'SMS_offSpikes_tailSpikes'} = tailSpikesOff';
dtabColumns{'SMS_offSpikes_tailSpikes', 'type'} = {'single'};


%% Best DS

% src = {'DrifTex_DSI_sp','DrifGrat_DSI_sp','MB_1000_DSI_sp','MB_500_DSI_sp','MB_250_DSI_sp'};
% ang = {'DrifTex_DSang_sp','DrifGrat_DSang_sp','MB_1000_DSang_sp','MB_500_DSang_sp','MB_250_DSang_sp'};
src = {'MB_2000_DSI_sp','MB_1000_DSI_sp','MB_500_DSI_sp','MB_250_DSI_sp'};
ang = {'MB_2000_DSang_sp','MB_1000_DSang_sp','MB_500_DSang_sp','MB_250_DSang_sp'};
for ci = 1:numCells
    dsis = dtab{ci, src};
    angs = dtab{ci, ang};
    [m, i] = max(dsis);
    dtab{ci,'best_DSI_sp'} = m;
    dtab{ci,'best_DSang_sp'} = angs(i);
    dtab{ci,'best_source'} = {src(i)};
end
dtabColumns{'best_DSI_sp', 'type'} = {'single'};
dtabColumns{'best_DSang_sp', 'type'} = {'single'};
dtabColumns{'best_source', 'type'} = {'string'};

%% Autocenter Ex In offset

diffX = dtab.spatial_ex_centerX - dtab.spatial_in_centerX; % vector inhibition to excitation (like soma to dendrites)
diffY = dtab.spatial_ex_centerY - dtab.spatial_in_centerY;

avgSigma = mean(dtab{:,{'spatial_in_sigma2X','spatial_ex_sigma2X','spatial_in_sigma2Y','spatial_ex_sigma2Y'}}, 2);
autocenterOffsetDistance = sqrt(diffX.^2 + diffY.^2);
autocenterOffsetDistanceNormalized = autocenterOffsetDistance ./ avgSigma;
autocenterOffsetDirections = rad2deg(angle(diffX + sqrt(-1) * diffY));
dtab.spatial_exin_offset = diffX + sqrt(-1) * diffY;
dtab.spatial_exin_offset_normalized = autocenterOffsetDistanceNormalized;
dtab.spatial_exin_offset_magnitude = autocenterOffsetDistance;
dtab.spatial_exin_offset_angle = autocenterOffsetDirections;
dtabColumns{'spatial_exin_offset', 'type'} = {'single'};
dtabColumns{'spatial_exin_offset_normalized', 'type'} = {'single'};
dtabColumns{'spatial_exin_offset_magnitude', 'type'} = {'single'};
dtabColumns{'spatial_exin_offset_angle', 'type'} = {'single'};


%% Autocenter On Off offset

diffX = dtab.spatial_on_centerX - dtab.spatial_off_centerX; % vector off to on
diffY = dtab.spatial_on_centerY - dtab.spatial_off_centerY;

avgSigma = mean(dtab{:,{'spatial_off_sigma2X','spatial_on_sigma2X','spatial_off_sigma2Y','spatial_on_sigma2Y'}}, 2);
autocenterOffsetDistance = sqrt(diffX.^2 + diffY.^2);
autocenterOffsetDistanceNormalized = autocenterOffsetDistance ./ avgSigma;
autocenterOffsetDirections = rad2deg(angle(diffX + sqrt(-1) * diffY));
dtab.spatial_onoff_offset = diffX + sqrt(-1) * diffY;
dtab.spatial_onoff_offset_normalized = autocenterOffsetDistanceNormalized;
dtab.spatial_onoff_offset_magnitude = autocenterOffsetDistance;
dtab.spatial_onoff_offset_angle = autocenterOffsetDirections;
dtabColumns{'spatial_onoff_offset', 'type'} = {'single'};
dtabColumns{'spatial_onoff_offset_normalized', 'type'} = {'single'};
dtabColumns{'spatial_onoff_offset_magnitude', 'type'} = {'single'};
dtabColumns{'spatial_onoff_offset_angle', 'type'} = {'single'};