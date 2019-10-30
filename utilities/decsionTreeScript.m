%%% Splits 2 and 3 (assuming they work)
DS_OS_types = {'ON-OFF DS dorsal' ,'ON-OFF DS nasal', 'ON-OFF DS temporal', 'ON-OFF DS ventral', 'ON DS dorsonasal', 'ON DS ventronasal', 'ON DS temporal', 'ON OS horizontal', 'ON OS vertical'};
LS_nonOFF_nonDSOS = ditchTypes(LS_ONandOO, DS_OS_types);

%% Split 4 - late ON cells vs. rest
lateTypes = {'LED', 'ON delayed'};
LS_nonOFF_nonDSOS = addParamForCellTypes(LS_nonOFF_nonDSOS, 'latencyType', lateTypes, 'late', 'early');
[crossValModel, errorRate, resultTable] = CellSeparator_2D(LS_nonOFF_nonDSOS, 'ONSET_latencyToMax', 'ONSET_avgHz', 'latencyType', 'late');
%ON bursty gets split 
%4 LEDs end up in the early side. They should probably be checked.
LS_nonOFF_nonDSOS_early = ditchTypes(LS_nonOFF_nonDSOS, lateTypes);
LS_nonOFF_nonDSOS_late = keepTypes(LS_nonOFF_nonDSOS, [lateTypes, 'ON bursty']);

%% Split 5 - sustained ON vs. trans ON and ON-OFF cells
susTypes = {'ON alpha', 'PixON', 'M2', 'ON delayed', 'ON bursty'};
LS_nonOFF_nonDSOS_early = addParamForCellTypes(LS_nonOFF_nonDSOS_early, 'kinetics', susTypes, 'sustained', 'transient');
[crossValModel, errorRate, resultTable] = CellSeparator_2D(LS_nonOFF_nonDSOS_early, 'ONSET_duration', 'stimInt_spikes', 'kinetics', 'sustained')

LS_nonOFF_nonDSOS_early_sus = keepTypes(LS_nonOFF_nonDSOS_early, susTypes);
LS_nonOFF_nonDSOS_early_trans = ditchTypes(LS_nonOFF_nonDSOS_early, susTypes);

%% Split 6 - OFF cells - high baseline and low maxFR to split off OFF sus alpha
[crossValModel, errorRate, resultTable] = CellSeparator_2D(LS_OFF, 'baseline_firing', 'afterstim_maxHz', 'cellType', 'OFF sustained alpha')
%off bursty split and a few bad ones, but otherwise works fine
LS_OFF_nonOFF_susAlpha = ditchTypes(LS_OFF, {'OFF sustained alpha'});

%% Split 7 - split out OFF OS and the like
lowFR_types = {'OFF OS - JAMB', 'OFF OS - symmetric'};
LS_OFF_nonOFF_susAlpha = addParamForCellTypes(LS_OFF_nonOFF_susAlpha, 'OFF_OS_like', lowFR_types, 'true', 'false');
[crossValModel, errorRate, resultTable] = CellSeparator_2D(LS_OFF_nonOFF_susAlpha, 'ONOFF_ratio', 'afterstim_maxHz', 'OFF_OS_like', 'true')
%6 OFF OS symmetric in the wrong place... check them. Too high FR
LS_OFF_OFF_OS_like = keepTypes(LS_OFF_nonOFF_susAlpha, lowFR_types);
LS_OFF_trans_and_med = ditchTypes(LS_OFF_nonOFF_susAlpha, lowFR_types);

%% Split 8 - split OFF trans. alpha and OFF med sus by baseline FR and high offset spike count
baseline_firing_types = {'SbC bursty (OFF bursty)', 'OFF transient alpha', 'OFF medium sustained'};
LS_OFF_trans_and_med = addParamForCellTypes(LS_OFF_trans_and_med, 'baselineActive', baseline_firing_types, 'true', 'false');
[crossValModel, errorRate, resultTable] = CellSeparator_2D(LS_OFF_trans_and_med, 'baseline_firing', 'OFFSET_spikes', 'baselineActive', 'true')
LS_OFF_trans_and_med_withBaseline = keepTypes(LS_OFF_trans_and_med, baseline_firing_types);
LS_OFF_trans_and_med_noBaseline = ditchTypes(LS_OFF_trans_and_med, baseline_firing_types);

%% Split 9 - shelf vs. trans trans split by duration and offset spikes
[crossValModel, errorRate, resultTable] = CellSeparator_2D(LS_OFF_trans_and_med_noBaseline, 'OFFSET_duration', 'OFFSET_spikes', 'cellType', 'OFF transient transient')

%% Split 10 - OFF trans. alpha vs. OFF med sus. Should be easy - maybe use SMS



