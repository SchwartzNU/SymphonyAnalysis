%% Secondary analysis


%% SMS peak and tail
for ci = 1:size(dtab,1)
    spotSize = dtab{ci, 'SMS_spotSize_sp'}{1};
    if ~isempty(spotSize)
        onspikes = dtab{ci, 'SMS_onSpikes'}{1};
        offspikes = dtab{ci, 'SMS_offSpikes'}{1};
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
    end
end

dtab{:,'SMS_onSpikes_prefSize'} = peakSizeOn';
dtab{:,'SMS_onSpikes_peakSpikes'} = peakValueOn';
dtab{:,'SMS_onSpikes_tailSpikes'} = tailSpikesOn';
dtab{:,'SMS_offSpikes_prefSize'} = peakSizeOff';
dtab{:,'SMS_offSpikes_peakSpikes'} = peakValueOff';
dtab{:,'SMS_offSpikes_tailSpikes'} = tailSpikesOff';

%% Best DS

src = {'DrifTex_DSI_sp','DrifGrat_DSI_sp','MB_1000_DSI_sp','MB_500_DSI_sp','MB_250_DSI_sp'};
ang = {'DrifTex_DSang_sp','DrifGrat_DSang_sp','MB_1000_DSang_sp','MB_500_DSang_sp','MB_250_DSang_sp'};
for ci = 1:numCells
    dsis = dtab{ci, src};
    angs = dtab{ci, ang};
    [m, i] = max(dsis);
    dtab{ci,'best_DSI_sp'} = m;
    dtab{ci,'best_DSang_sp'} = angs(i);
    dtab{ci,'best_source'} = {src(i)};
end

%% Autocenter offset

diffX = dtab.spatial_ex_centerX - dtab.spatial_in_centerX;
diffY = dtab.spatial_ex_centerY - dtab.spatial_in_centerY;
avgSigma = mean(dtab{:,{'spatial_in_sigma2X','spatial_ex_sigma2X','spatial_in_sigma2Y','spatial_ex_sigma2Y'}}, 2);
autocenterOffsetDistance = sqrt(diffX.^2 + diffY.^2);
autocenterOffsetDistanceNormalized = autocenterOffsetDistance ./ avgSigma;
autocenterOffsetDirections = angle(diffX + sqrt(-1) * diffY);
dtab.spatial_exin_offset = autocenterOffsetDistance .* exp(sqrt(-1) * autocenterOffsetDirections);